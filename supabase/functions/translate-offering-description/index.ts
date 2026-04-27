// deno-lint-ignore-file no-explicit-any
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const DEEPSEEK_API_KEY = Deno.env.get("DEEPSEEK_API_KEY")!;

const TARGET_LANGS: Array<{ code: "es" | "en" | "fr" | "pt" }> = [
  { code: "es" },
  { code: "en" },
  { code: "fr" },
  { code: "pt" },
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
      offering_id,
      source_name,
      source_description,
      source_lang = "es",
      overwrite = true,
    } = await req.json();

    if (!offering_id || !source_name) {
      return json({ error: "offering_id and source_name are required" }, 400);
    }

    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE);

    // Trae info mínima del offering + negocio + categoría para contexto
    const { data: offering, error: offErr } = await supabase
      .from("offerings")
      .select(
        "id, type, price_mxn, business:businesses(name, category:categories(slug))",
      )
      .eq("id", offering_id)
      .single();
    if (offErr || !offering) return json({ error: "offering not found" }, 404);

    // Catálogo de idiomas
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

    const businessName = (offering as any).business?.name ?? "";
    const categorySlug =
      (offering as any).business?.category?.slug ?? "negocio";

    const prompt = buildPrompt({
      offeringType: offering.type,
      businessName,
      category: categorySlug,
      sourceLang: source_lang,
      sourceName: source_name,
      sourceDescription: source_description ?? "",
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
              "You translate short product/service listings for tourists. Keep meaning intact, warm tone, concise. Do NOT translate the business name. Respond ONLY with valid JSON.",
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
    let translations: Record<string, { name: string; description: string }>;
    try {
      translations = JSON.parse(raw);
    } catch {
      return json({ error: "invalid_json_from_model", raw }, 502);
    }

    // Upsert en offering_translations
    const rows = TARGET_LANGS.filter(
      (l) => translations[l.code]?.name && langIdByCode[l.code],
    ).map((l) => ({
      offering_id,
      language_id: langIdByCode[l.code],
      name: translations[l.code].name.trim(),
      description: (translations[l.code].description ?? "").trim() || null,
    }));

    if (rows.length === 0)
      return json({ error: "no_translations_generated" }, 502);

    const { error: upErr } = await supabase
      .from("offering_translations")
      .upsert(rows, {
        onConflict: "offering_id,language_id",
        ignoreDuplicates: !overwrite,
      });
    if (upErr)
      return json({ error: "upsert_failed", detail: upErr.message }, 500);

    return json({ ok: true, offering_id, languages: rows });
  } catch (e) {
    return json({ error: "unexpected", detail: String(e) }, 500);
  }
});

function buildPrompt(args: {
  offeringType: string;
  businessName: string;
  category: string;
  sourceLang: string;
  sourceName: string;
  sourceDescription: string;
}) {
  return `
Business: ${args.businessName}
Category: ${args.category}
Offering type: ${args.offeringType}
Source language: ${args.sourceLang}

Source name: ${args.sourceName}
Source description: ${args.sourceDescription || "(none)"}

Task: produce a translated NAME and DESCRIPTION for this ${args.offeringType} in EACH of these languages:
- es (Spanish, Mexico)
- en (English)
- fr (French)
- pt (Portuguese, Brazil)

Rules:
- "name" must be short (max 6 words), suitable for a menu or catalog item.
- "description" must be 1-2 short sentences, warm and inviting tone.
- Keep the business name untranslated if it appears.
- Do not invent ingredients or facts not present in the source.
- No emojis, no markdown.
- If source description is "(none)", generate a brief plausible description from the name only.

Return ONLY this JSON shape:
{
  "es": {"name": "...", "description": "..."},
  "en": {"name": "...", "description": "..."},
  "fr": {"name": "...", "description": "..."},
  "pt": {"name": "...", "description": "..."}
}
`.trim();
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}
