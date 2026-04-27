// deno-lint-ignore-file no-explicit-any
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const DEEPSEEK_API_KEY = Deno.env.get("DEEPSEEK_API_KEY")!;

const TARGET_LANGS: Array<{ code: "es" | "en" | "fr" | "pt"; label: string }> =
  [
    { code: "es", label: "Spanish (Mexico)" },
    { code: "en", label: "English" },
    { code: "fr", label: "French" },
    { code: "pt", label: "Portuguese (Brazil)" },
  ];

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    const {
      business_id,
      source_description,
      source_lang = "es",
      overwrite = true,
    } = await req.json();

    if (!business_id || !source_description) {
      return json(
        { error: "business_id and source_description are required" },
        400,
      );
    }

    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE);

    // Trae info mínima del negocio para dar contexto al modelo
    const { data: biz, error: bizErr } = await supabase
      .from("businesses")
      .select("id, name, category:categories(slug)")
      .eq("id", business_id)
      .single();
    if (bizErr || !biz) return json({ error: "business not found" }, 404);

    // Catálogo de idiomas (id por code)
    const { data: langs, error: langErr } = await supabase
      .from("languages")
      .select("id, code")
      .in(
        "code",
        TARGET_LANGS.map((l) => l.code),
      );
    if (langErr || !langs)
      return json({ error: "languages lookup failed" }, 500);

    const langIdByCode: Record<string, string> = Object.fromEntries(
      langs.map((l: any) => [l.code, l.id]),
    );

    // Prompt único: pedimos JSON con todas las traducciones de un solo viaje
    const prompt = buildPrompt({
      name: biz.name,
      category: (biz as any).category?.slug ?? "negocio",
      sourceLang: source_lang,
      sourceText: source_description,
    });

    const dsRes = await fetch("https://api.deepseek.com/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${DEEPSEEK_API_KEY}`,
      },
      body: JSON.stringify({
        model: "deepseek-chat",
        temperature: 0.4,
        response_format: { type: "json_object" },
        messages: [
          {
            role: "system",
            content:
              "You translate and lightly localize short business descriptions for tourists. Keep the original meaning, warm tone, 2-4 sentences. Do NOT translate the business name. Respond ONLY with valid JSON.",
          },
          { role: "user", content: prompt },
        ],
      }),
    });

    if (!dsRes.ok) {
      const t = await dsRes.text();
      return json({ error: "deepseek_error", detail: t }, 502);
    }

    const dsJson = await dsRes.json();
    const raw = dsJson.choices?.[0]?.message?.content ?? "{}";
    let translations: Record<string, string>;
    try {
      translations = JSON.parse(raw);
    } catch {
      return json({ error: "invalid_json_from_model", raw }, 502);
    }

    // Upsert en business_translations
    const rows = TARGET_LANGS.filter(
      (l) => translations[l.code] && langIdByCode[l.code],
    ).map((l) => ({
      business_id,
      language_id: langIdByCode[l.code],
      description: translations[l.code].trim(),
    }));

    if (rows.length === 0)
      return json({ error: "no_translations_generated" }, 502);

    const { error: upErr } = await supabase
      .from("business_translations")
      .upsert(rows, {
        onConflict: "business_id,language_id",
        ignoreDuplicates: !overwrite,
      });
    if (upErr)
      return json({ error: "upsert_failed", detail: upErr.message }, 500);

    return json({
      ok: true,
      business_id,
      languages: rows.map((r) => ({
        language_id: r.language_id,
        description: r.description,
      })),
    });
  } catch (e) {
    return json({ error: "unexpected", detail: String(e) }, 500);
  }
});

function buildPrompt(args: {
  name: string;
  category: string;
  sourceLang: string;
  sourceText: string;
}) {
  return `
Business name: ${args.name}
Category: ${args.category}
Source language: ${args.sourceLang}
Source description:
"""${args.sourceText}"""

Task: produce a tourist-friendly description (2-4 sentences) in EACH of these languages:
- es (Spanish, Mexico)
- en (English)
- fr (French)
- pt (Portuguese, Brazil)

Rules:
- Keep the business name untranslated.
- Warm, inviting tone, no emojis, no markdown.
- Do not invent facts not present in the source.

Return ONLY this JSON shape:
{"es":"...","en":"...","fr":"...","pt":"..."}
`.trim();
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}
