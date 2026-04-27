// =====================================================================
// CONOCEMEX — Edge Function: mp-create-charge
// Propósito: El microempresario pide generar un QR de cobro por X pesos.
// Esta función crea una preferencia en Mercado Pago usando el
// access_token del vendedor, guarda la transacción en estado 'pending'
// y devuelve a Flutter la URL init_point (que Flutter convierte en QR).
//
// Llamada desde el frontend (Flutter):
//   POST /functions/v1/mp-create-charge
//   Headers: Authorization: Bearer <supabase_jwt_del_microempresario>
//   Body: {
//     "business_id": "<uuid>",
//     "amount_mxn": 200.00,
//     "description": "2 tacos al pastor"   // opcional
//   }
//
// Respuesta 200:
//   {
//     "transaction_id": "<uuid>",
//     "preference_id": "1234567890-abc-def",
//     "init_point": "https://www.mercadopago.com.mx/checkout/v1/redirect?pref_id=..."
//   }
// =====================================================================

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

// ----- Env vars -----
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// Base URL del proyecto para armar las back_urls sin hardcodear el ref
const PROJECT_BASE = SUPABASE_URL.replace(/\/+$/, "");

// URL de la PWA pública (Next.js) donde MP redirige al turista después
// del pago. Por ahora todos los casos apuntan a payment-success (MVP
// happy path); post-MVP se separan en failure/pending.
const PWA_PAYMENT_SUCCESS_URL =
  "https://conocemex.jaguarmind.network/payment-success";
const BACK_URL_SUCCESS = PWA_PAYMENT_SUCCESS_URL;
const BACK_URL_FAILURE = PWA_PAYMENT_SUCCESS_URL;
const BACK_URL_PENDING = PWA_PAYMENT_SUCCESS_URL;

// URL del webhook que MP llamará cuando el pago cambie de estado
const NOTIFICATION_URL = `${PROJECT_BASE}/functions/v1/mp-webhook`;

// Endpoint de preferencias de MP
const MP_PREFERENCES_URL = "https://api.mercadopago.com/checkout/preferences";

// Reglas de negocio
const MIN_AMOUNT_MXN = 5; // mínimo que acepta MP México
const MAX_AMOUNT_MXN = 250_000; // tope razonable anti-abuso

// ----- CORS -----
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }

  // ----- 1. Validar JWT -----
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return jsonResponse({ error: "unauthorized" }, 401);
  }
  const jwt = authHeader.slice("Bearer ".length);

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
  let body: {
    business_id?: string;
    amount_mxn?: number;
    description?: string;
  };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "invalid_json" }, 400);
  }

  const businessId = body.business_id;
  const amount = Number(body.amount_mxn);
  const description = (body.description ?? "").trim().slice(0, 200);

  if (!businessId || typeof businessId !== "string") {
    return jsonResponse({ error: "business_id_required" }, 400);
  }
  if (!Number.isFinite(amount)) {
    return jsonResponse({ error: "amount_invalid" }, 400);
  }
  if (amount < MIN_AMOUNT_MXN) {
    return jsonResponse({ error: "amount_too_low", min: MIN_AMOUNT_MXN }, 400);
  }
  if (amount > MAX_AMOUNT_MXN) {
    return jsonResponse({ error: "amount_too_high", max: MAX_AMOUNT_MXN }, 400);
  }
  // Redondear a 2 decimales para evitar floats raros
  const amountRounded = Math.round(amount * 100) / 100;

  // ----- 3. Verificar ownership del business + obtener datos del negocio -----
  const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  const { data: business, error: bizErr } = await admin
    .from("businesses")
    .select("id, owner_id, name")
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

  // ----- 4. Obtener access_token del vendedor -----
  const { data: mpAccount, error: mpErr } = await admin
    .from("mp_accounts")
    .select("access_token, expires_at, live_mode")
    .eq("business_id", businessId)
    .maybeSingle();

  if (mpErr) {
    return jsonResponse({ error: "db_error", detail: mpErr.message }, 500);
  }
  if (!mpAccount) {
    return jsonResponse({ error: "mp_not_connected" }, 409);
  }
  if (new Date(mpAccount.expires_at).getTime() < Date.now()) {
    // TODO(paso siguiente): refrescar automáticamente con refresh_token.
    // Por ahora, pedimos al micro que reconecte.
    return jsonResponse({ error: "mp_token_expired" }, 409);
  }

  // ----- 5. Crear transacción en estado pending -----
  // La creamos ANTES de llamar a MP para tener el transaction_id y poder
  // pasarlo como external_reference. Si la llamada a MP falla, la
  // marcamos como 'failed' al final.
  const { data: transaction, error: txErr } = await admin
    .from("transactions")
    .insert({
      tourist_id: null, // turista anónimo — se llenará vía webhook si aplica
      business_id: businessId,
      amount_mxn: amountRounded,
      currency_original: "MXN",
      amount_original: amountRounded,
      exchange_rate: 1,
      payment_method: "mercado_pago",
      status: "pending",
    })
    .select("id")
    .single();

  if (txErr || !transaction) {
    console.error("transactions insert failed:", txErr);
    return jsonResponse(
      { error: "db_error", detail: txErr?.message ?? "insert failed" },
      500,
    );
  }

  const transactionId = transaction.id;

  // ----- 6. Crear preferencia en Mercado Pago -----
  const itemTitle = description || `Cobro ${business.name}`;

  const preferencePayload = {
    items: [
      {
        id: transactionId,
        title: itemTitle,
        description: description || undefined,
        quantity: 1,
        currency_id: "MXN",
        unit_price: amountRounded,
      },
    ],
    external_reference: transactionId, // puente con el webhook
    notification_url: NOTIFICATION_URL,
    back_urls: {
      success: BACK_URL_SUCCESS,
      failure: BACK_URL_FAILURE,
      pending: BACK_URL_PENDING,
    },
    auto_return: "approved",
    statement_descriptor: "CONOCEMEX",
    binary_mode: false,
    metadata: {
      business_id: businessId,
      transaction_id: transactionId,
    },
  };

  let prefJson: {
    id?: string;
    init_point?: string;
    sandbox_init_point?: string;
    [k: string]: unknown;
  };

  try {
    const prefRes = await fetch(MP_PREFERENCES_URL, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${mpAccount.access_token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(preferencePayload),
    });

    const text = await prefRes.text();
    if (!prefRes.ok) {
      console.error("MP preference failed:", prefRes.status, text);
      // marcar transacción como fallida
      await admin
        .from("transactions")
        .update({ status: "failed" })
        .eq("id", transactionId);
      return jsonResponse(
        { error: "mp_preference_failed", status: prefRes.status, detail: text },
        502,
      );
    }
    prefJson = JSON.parse(text);
  } catch (e) {
    console.error("MP preference exception:", e);
    await admin
      .from("transactions")
      .update({ status: "failed" })
      .eq("id", transactionId);
    return jsonResponse({ error: "mp_unreachable" }, 502);
  }

  if (!prefJson.id || !prefJson.init_point) {
    console.error("MP preference returned invalid shape:", prefJson);
    await admin
      .from("transactions")
      .update({ status: "failed" })
      .eq("id", transactionId);
    return jsonResponse({ error: "mp_invalid_response" }, 502);
  }

  // ----- 7. Guardar preference_id en la transacción -----
  const { error: updateErr } = await admin
    .from("transactions")
    .update({ mp_preference_id: prefJson.id })
    .eq("id", transactionId);

  if (updateErr) {
    console.error("transactions update mp_preference_id failed:", updateErr);
    // No es fatal — la preferencia existe en MP. Pero avisamos.
    return jsonResponse(
      {
        error: "tx_update_failed",
        detail: updateErr.message,
        // Devolvemos igual los datos para que Flutter pueda continuar
        transaction_id: transactionId,
        preference_id: prefJson.id,
        init_point: prefJson.init_point,
      },
      207, // multi-status: hubo un warning pero el cobro existe
    );
  }

  // ----- 8. Respuesta OK -----
  return jsonResponse({
    transaction_id: transactionId,
    preference_id: prefJson.id,
    init_point: prefJson.init_point,
    // sandbox_init_point solo aparece en modo test
    sandbox_init_point: prefJson.sandbox_init_point ?? null,
    amount_mxn: amountRounded,
  });
});
