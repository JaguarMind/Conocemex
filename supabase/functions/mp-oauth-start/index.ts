// =====================================================================
// CONOCEMEX — Edge Function: mp-oauth-start
// Propósito: El microempresario pide conectar su cuenta de Mercado Pago.
// Devuelve la URL de autorización a la que el frontend debe redirigir.
//
// Llamada desde el frontend:
//   POST /functions/v1/mp-oauth-start
//   Headers: Authorization: Bearer <supabase_jwt_del_microempresario>
//   Body:    { "business_id": "<uuid>" }
//
// Respuesta:
//   200 { "authorization_url": "https://auth.mercadopago.com.mx/authorization?..." }
//   400 { "error": "..." }
//   401 { "error": "unauthorized" }
//   403 { "error": "not_business_owner" }
// =====================================================================

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

// ----- Env vars (configurar con `supabase secrets set ...`) -----
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const MP_CLIENT_ID = Deno.env.get("MP_CLIENT_ID")!;
const MP_REDIRECT_URI = Deno.env.get("MP_REDIRECT_URI")!; // ej: https://<proj>.supabase.co/functions/v1/mp-oauth-callback

// MP México. Si más adelante quieres soportar otros países, esto se parametriza.
const MP_AUTH_BASE = "https://auth.mercadopago.com.mx/authorization";

// ----- CORS -----
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function generateState(): string {
  // 32 bytes random → base64url ≈ 43 chars
  const bytes = new Uint8Array(32);
  crypto.getRandomValues(bytes);
  return btoa(String.fromCharCode(...bytes))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

serve(async (req) => {
  // Preflight CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }

  // ----- 1. Validar JWT del microempresario -----
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return jsonResponse({ error: "unauthorized" }, 401);
  }
  const jwt = authHeader.slice("Bearer ".length);

  // Cliente con anon key + el JWT del usuario, solo para leer auth.users
  const userClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    global: { headers: { Authorization: `Bearer ${jwt}` } },
    auth: { persistSession: false },
  });

  const { data: userData, error: userErr } = await userClient.auth.getUser(jwt);
  if (userErr || !userData?.user) {
    return jsonResponse({ error: "unauthorized" }, 401);
  }
  const userId = userData.user.id;

  // ----- 2. Validar body -----
  let body: { business_id?: string };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "invalid_json" }, 400);
  }

  const businessId = body.business_id;
  if (!businessId || typeof businessId !== "string") {
    return jsonResponse({ error: "business_id_required" }, 400);
  }

  // ----- 3. Verificar que el business le pertenece al usuario -----
  // Usamos service_role para no depender de RLS (que ya valida igual,
  // pero queremos error explícito).
  const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  const { data: business, error: bizErr } = await adminClient
    .from("businesses")
    .select("id, owner_id")
    .eq("id", businessId)
    .maybeSingle();

  if (bizErr) {
    return jsonResponse({ error: "db_error", detail: bizErr.message }, 500);
  }
  if (!business) {
    return jsonResponse({ error: "business_not_found" }, 404);
  }
  if (business.owner_id !== userId) {
    return jsonResponse({ error: "not_business_owner" }, 403);
  }

  // ----- 4. Generar y persistir state -----
  const state = generateState();

  const { error: stateErr } = await adminClient.from("mp_oauth_states").insert({
    state,
    business_id: businessId,
    owner_id: userId,
  });

  if (stateErr) {
    return jsonResponse(
      { error: "state_persist_failed", detail: stateErr.message },
      500,
    );
  }

  // ----- 5. Armar URL de autorización de MP -----
  const url = new URL(MP_AUTH_BASE);
  url.searchParams.set("client_id", MP_CLIENT_ID);
  url.searchParams.set("response_type", "code");
  url.searchParams.set("platform_id", "mp");
  url.searchParams.set("redirect_uri", MP_REDIRECT_URI);
  url.searchParams.set("state", state);

  return jsonResponse({ authorization_url: url.toString() });
});
