// =====================================================================
// CONOCEMEX — Edge Function: mp-webhook
// Propósito: Recibir notificaciones de Mercado Pago cuando un pago
// cambia de estado, verificar el pago consultando directo a MP, y
// actualizar la transacción correspondiente en nuestra base.
//
// Llamada desde Mercado Pago (POST):
//   POST /functions/v1/mp-webhook
//   Body típico:
//   {
//     "action": "payment.updated",
//     "api_version": "v1",
//     "data": { "id": "12345678" },
//     "date_created": "2026-04-08T...",
//     "id": 99999999,
//     "live_mode": false,
//     "type": "payment",
//     "user_id": "1234567890"
//   }
//
// Respuestas:
//   200 → procesado o ignorado (siempre que no haya error de servidor)
//   400 → body inválido
//   500 → error interno
//
// Seguridad:
//   - NO validamos x-signature porque MP no nos muestra la secret
//     (bug del panel). En su lugar hacemos VERIFICACIÓN CRUZADA:
//     siempre consultamos el pago directo a MP antes de tocar la base.
//     Un atacante tendría que adivinar payment_ids reales de vendedores
//     específicos para falsificar una notificación, lo cual es
//     prácticamente imposible.
// =====================================================================

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

// ----- Env vars -----
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const MP_PAYMENTS_BASE = "https://api.mercadopago.com/v1/payments";

// ----- Helpers -----

function ok(body: unknown = { received: true }): Response {
  return new Response(JSON.stringify(body), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
}

function badRequest(reason: string): Response {
  console.warn("400:", reason);
  return new Response(JSON.stringify({ error: reason }), {
    status: 400,
    headers: { "Content-Type": "application/json" },
  });
}

function serverError(reason: string): Response {
  console.error("500:", reason);
  return new Response(JSON.stringify({ error: reason }), {
    status: 500,
    headers: { "Content-Type": "application/json" },
  });
}

// Mapeo de status MP → status interno de CONOCEMEX
function mapPaymentStatus(
  mpStatus: string,
): "completed" | "failed" | "refunded" | "pending" {
  switch (mpStatus) {
    case "approved":
      return "completed";
    case "rejected":
    case "cancelled":
      return "failed";
    case "refunded":
    case "charged_back":
      return "refunded";
    case "pending":
    case "in_process":
    case "authorized":
    case "in_mediation":
    default:
      return "pending";
  }
}

// ----- Handler -----

serve(async (req) => {
  // MP siempre llama por POST. GET y otros los ignoramos amable.
  if (req.method === "GET") {
    // Útil para ping manual desde el navegador en debugging
    return ok({ message: "mp-webhook alive" });
  }
  if (req.method !== "POST") {
    return ok({ ignored: "method_not_post" });
  }

  // ----- 1. Parsear body -----
  let body: {
    type?: string;
    action?: string;
    data?: { id?: string | number };
    user_id?: string | number;
    live_mode?: boolean;
    [k: string]: unknown;
  };

  try {
    body = await req.json();
  } catch {
    return badRequest("invalid_json");
  }

  console.log("MP webhook received:", JSON.stringify(body));

  // ----- 2. Filtrar tipos que no nos interesan -----
  // Solo procesamos eventos de tipo 'payment'. MP también puede enviar
  // 'merchant_order', 'plan', etc. — los ignoramos con 200 OK para que
  // MP no reintente.
  if (body.type !== "payment") {
    return ok({ ignored: "not_payment_type", type: body.type ?? null });
  }

  const paymentId = body.data?.id;
  const mpUserId = body.user_id;

  if (!paymentId) {
    return badRequest("missing_payment_id");
  }
  if (!mpUserId) {
    return badRequest("missing_user_id");
  }

  const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  // ----- 3. Buscar el access_token del vendedor -----
  // El user_id del webhook es el mp_user_id del vendedor en mp_accounts.
  const { data: mpAccount, error: mpAccountErr } = await admin
    .from("mp_accounts")
    .select("business_id, access_token, expires_at")
    .eq("mp_user_id", String(mpUserId))
    .maybeSingle();

  if (mpAccountErr) {
    return serverError("db_error: " + mpAccountErr.message);
  }
  if (!mpAccount) {
    // El user_id del webhook no corresponde a ningún negocio nuestro.
    // Puede pasar si MP llama por error o si alguien intenta spam.
    // Respondemos 200 para que MP no reintente, pero logueamos.
    console.warn("webhook for unknown mp_user_id:", mpUserId);
    return ok({ ignored: "unknown_seller" });
  }

  if (new Date(mpAccount.expires_at).getTime() < Date.now()) {
    // Token vencido — no podemos consultar a MP. Logueamos y respondemos
    // 200 para no encolar reintentos infinitos. El micro tendrá que
    // reconectar MP y la transacción quedará pending.
    console.error("seller token expired for mp_user_id:", mpUserId);
    return ok({ ignored: "seller_token_expired" });
  }

  // ----- 4. VERIFICACIÓN CRUZADA con MP -----
  // Esta es la protección principal. Aunque la firma del webhook no la
  // validamos, consultar el pago directo a MP confirma que el pago es
  // real y nos da los datos auténticos.
  let paymentData: {
    id: number | string;
    status: string;
    status_detail?: string;
    external_reference?: string | null;
    transaction_amount?: number;
    payer?: { id?: number | string; email?: string };
    [k: string]: unknown;
  };

  try {
    const mpRes = await fetch(`${MP_PAYMENTS_BASE}/${paymentId}`, {
      method: "GET",
      headers: {
        Authorization: `Bearer ${mpAccount.access_token}`,
        Accept: "application/json",
      },
    });

    const text = await mpRes.text();

    if (mpRes.status === 404) {
      // El payment_id no existe en MP. Es muy probable que sea spoofing.
      console.warn("payment not found in MP:", paymentId);
      return ok({ ignored: "payment_not_found" });
    }
    if (!mpRes.ok) {
      console.error("MP get payment failed:", mpRes.status, text);
      return serverError("mp_get_payment_failed");
    }

    paymentData = JSON.parse(text);
  } catch (e) {
    console.error("MP get payment exception:", e);
    return serverError("mp_unreachable");
  }

  // ----- 5. Extraer external_reference (= nuestro transaction_id) -----
  const transactionId = paymentData.external_reference;

  if (!transactionId) {
    // Pago real pero sin nuestro external_reference. Probablemente
    // fue creado fuera de CONOCEMEX (ej. el vendedor cobró por su lado).
    // No es nuestro problema, lo ignoramos.
    return ok({ ignored: "no_external_reference" });
  }

  // ----- 6. Buscar la transacción en nuestra base -----
  const { data: transaction, error: txErr } = await admin
    .from("transactions")
    .select("id, business_id, status, amount_mxn")
    .eq("id", transactionId)
    .maybeSingle();

  if (txErr) {
    return serverError("db_error: " + txErr.message);
  }
  if (!transaction) {
    // El external_reference apunta a una transacción que no existe en
    // nuestra base. Posible si se borró manualmente o si es de otro
    // ambiente. Ignorar.
    console.warn("transaction not found:", transactionId);
    return ok({ ignored: "transaction_not_found" });
  }

  // Sanity check: la transacción debe ser del mismo business que el
  // vendedor del webhook. Si no, hay algo muy raro.
  if (transaction.business_id !== mpAccount.business_id) {
    console.error(
      "business mismatch:",
      "tx.business_id=",
      transaction.business_id,
      "mp.business_id=",
      mpAccount.business_id,
    );
    return ok({ ignored: "business_mismatch" });
  }

  // ----- 7. Actualizar la transacción -----
  const newStatus = mapPaymentStatus(paymentData.status);

  // Si ya estaba en estado terminal, no degradar (idempotencia).
  // Ej: si ya era 'completed' y llega un webhook duplicado, no la
  // movemos a 'pending' aunque MP nos lo diga.
  const isAlreadyTerminal =
    transaction.status === "completed" ||
    transaction.status === "refunded" ||
    transaction.status === "failed";

  if (isAlreadyTerminal && newStatus === "pending") {
    return ok({ ignored: "already_terminal", current: transaction.status });
  }

  const { error: updateErr } = await admin
    .from("transactions")
    .update({
      status: newStatus,
      payment_provider_id: String(paymentData.id),
    })
    .eq("id", transactionId);

  if (updateErr) {
    return serverError("update_failed: " + updateErr.message);
  }

  console.log(
    `transaction ${transactionId} → ${newStatus}`,
    `(payment ${paymentData.id}, mp_status=${paymentData.status})`,
  );

  return ok({
    processed: true,
    transaction_id: transactionId,
    new_status: newStatus,
    mp_status: paymentData.status,
  });
});
