// =====================================================================
// CONOCEMEX — Edge Function: mp-oauth-callback
// Propósito: Recibir el redirect de Mercado Pago después de que el
// microempresario autoriza, intercambiar el `code` por tokens, y
// guardarlos en `mp_accounts`.
//
// Llamada desde Mercado Pago (GET):
//   GET /functions/v1/mp-oauth-callback?code=TG-xxx&state=yyy
//
// Respuesta: HTML (página de éxito o de error).
// =====================================================================

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

// ----- Env vars -----
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const MP_CLIENT_ID = Deno.env.get("MP_CLIENT_ID")!;
const MP_CLIENT_SECRET = Deno.env.get("MP_CLIENT_SECRET")!;
const MP_REDIRECT_URI = Deno.env.get("MP_REDIRECT_URI")!;

const MP_TOKEN_URL = "https://api.mercadopago.com/oauth/token";
const LOGO_URL =
  "https://res.cloudinary.com/dmcrt5aoi/image/upload/v1775684650/conocemex_logo_tk4j0i.jpg";

// ===== HTML helpers =====================================================

function htmlResponse(body: string, status = 200): Response {
  return new Response(body, {
    status,
    headers: { "Content-Type": "text/html; charset=utf-8" },
  });
}

function pageShell(opts: {
  title: string;
  iconColor: string; // hex
  iconSymbol: string; // ✓ ✕ ⚠
  heading: string;
  message: string;
  ctaText: string;
}): string {
  return `<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <title>${opts.title} — CONOCEMEX</title>
  <style>
    :root {
      --bg: #0b1020;
      --card: #111733;
      --text: #f4f6ff;
      --muted: #aab1cc;
      --accent: ${opts.iconColor};
    }
    * { box-sizing: border-box; }
    html, body {
      margin: 0; padding: 0; min-height: 100vh;
      background: radial-gradient(1200px 600px at 50% -10%, #1b2452 0%, var(--bg) 60%);
      color: var(--text);
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
      -webkit-font-smoothing: antialiased;
    }
    .wrap {
      min-height: 100vh;
      display: flex; align-items: center; justify-content: center;
      padding: 24px;
    }
    .card {
      width: 100%;
      max-width: 420px;
      background: var(--card);
      border: 1px solid rgba(255,255,255,0.06);
      border-radius: 20px;
      padding: 32px 28px;
      text-align: center;
      box-shadow: 0 30px 80px rgba(0,0,0,0.45);
    }
    .logo {
      width: 88px; height: 88px;
      object-fit: cover;
      border-radius: 18px;
      margin: 0 auto 20px;
      display: block;
      background: #fff;
    }
    .icon {
      width: 64px; height: 64px;
      border-radius: 50%;
      background: var(--accent);
      color: #0b1020;
      font-size: 36px;
      font-weight: 700;
      display: flex; align-items: center; justify-content: center;
      margin: 0 auto 18px;
    }
    h1 {
      font-size: 22px;
      margin: 0 0 10px;
      letter-spacing: -0.01em;
    }
    p {
      color: var(--muted);
      font-size: 15px;
      line-height: 1.55;
      margin: 0 0 22px;
    }
    .cta {
      display: inline-block;
      background: var(--accent);
      color: #0b1020;
      font-weight: 600;
      font-size: 15px;
      padding: 12px 22px;
      border-radius: 12px;
      text-decoration: none;
    }
    .brand {
      margin-top: 22px;
      font-size: 12px;
      letter-spacing: 0.12em;
      text-transform: uppercase;
      color: #6e779b;
    }
  </style>
</head>
<body>
  <div class="wrap">
    <main class="card">
      <img class="logo" src="${LOGO_URL}" alt="CONOCEMEX">
      <div class="icon">${opts.iconSymbol}</div>
      <h1>${opts.heading}</h1>
      <p>${opts.message}</p>
      <a class="cta" href="#" onclick="window.close();return false;">${opts.ctaText}</a>
      <div class="brand">CONOCEMEX</div>
    </main>
  </div>
</body>
</html>`;
}

function successPage(): string {
  return pageShell({
    title: "Cuenta conectada",
    iconColor: "#22c55e",
    iconSymbol: "✓",
    heading: "¡Cuenta conectada!",
    message:
      "Tu cuenta de Mercado Pago quedó conectada a CONOCEMEX. Ya puedes volver a la aplicación para empezar a recibir pagos de turistas.",
    ctaText: "Volver a la app",
  });
}

function errorPage(headingMsg: string, detailMsg: string): string {
  return pageShell({
    title: "Error",
    iconColor: "#ef4444",
    iconSymbol: "✕",
    heading: headingMsg,
    message: detailMsg,
    ctaText: "Volver a la app",
  });
}

function expiredPage(): string {
  return pageShell({
    title: "Enlace expirado",
    iconColor: "#f59e0b",
    iconSymbol: "⚠",
    heading: "Enlace expirado",
    message:
      "El enlace de autorización venció o ya fue utilizado. Vuelve a la aplicación de CONOCEMEX e intenta conectar tu cuenta de Mercado Pago de nuevo.",
    ctaText: "Volver a la app",
  });
}

// ===== Handler ==========================================================

serve(async (req) => {
  if (req.method !== "GET") {
    return htmlResponse(
      errorPage("Método no permitido", "Esta página solo acepta GET."),
      405,
    );
  }

  const url = new URL(req.url);
  const code = url.searchParams.get("code");
  const state = url.searchParams.get("state");
  const mpError = url.searchParams.get("error");

  // Caso: el user canceló o MP devolvió error
  if (mpError) {
    const desc =
      url.searchParams.get("error_description") ??
      "Mercado Pago devolvió un error.";
    return htmlResponse(errorPage("No se pudo conectar", desc), 400);
  }

  if (!code || !state) {
    return htmlResponse(
      errorPage(
        "Solicitud inválida",
        "Faltan parámetros en el redirect de Mercado Pago.",
      ),
      400,
    );
  }

  const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  // ----- 1. Buscar el state -----
  const { data: stateRow, error: stateErr } = await admin
    .from("mp_oauth_states")
    .select("state, business_id, owner_id, expires_at, consumed_at")
    .eq("state", state)
    .maybeSingle();

  if (stateErr) {
    console.error("state lookup failed:", stateErr);
    return htmlResponse(
      errorPage(
        "Error interno",
        "No pudimos validar tu solicitud. Inténtalo de nuevo.",
      ),
      500,
    );
  }

  if (!stateRow) {
    return htmlResponse(expiredPage(), 400);
  }

  if (stateRow.consumed_at) {
    return htmlResponse(expiredPage(), 400);
  }

  if (new Date(stateRow.expires_at).getTime() < Date.now()) {
    return htmlResponse(expiredPage(), 400);
  }

  // ----- 2. Marcar el state como consumido (anti-replay) -----
  // Lo hacemos antes del intercambio para que aunque MP responda lento,
  // un atacante no pueda reusar el mismo state en otra petición.
  const { error: consumeErr } = await admin
    .from("mp_oauth_states")
    .update({ consumed_at: new Date().toISOString() })
    .eq("state", state)
    .is("consumed_at", null); // condición de carrera

  if (consumeErr) {
    console.error("consume state failed:", consumeErr);
    return htmlResponse(
      errorPage("Error interno", "No pudimos validar tu solicitud."),
      500,
    );
  }

  // ----- 3. Intercambiar el code por tokens en MP -----
  let tokenJson: {
    access_token: string;
    refresh_token: string;
    user_id: number | string;
    public_key?: string;
    live_mode?: boolean;
    expires_in: number;
    scope?: string;
    token_type?: string;
  };

  try {
    const tokenRes = await fetch(MP_TOKEN_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        Accept: "application/json",
      },
      body: new URLSearchParams({
        client_id: MP_CLIENT_ID,
        client_secret: MP_CLIENT_SECRET,
        grant_type: "authorization_code",
        code,
        redirect_uri: MP_REDIRECT_URI,
      }),
    });

    const text = await tokenRes.text();
    if (!tokenRes.ok) {
      console.error("MP token exchange failed:", tokenRes.status, text);
      return htmlResponse(
        errorPage(
          "No se pudo conectar",
          "Mercado Pago rechazó la solicitud. Inténtalo de nuevo desde la app.",
        ),
        400,
      );
    }
    tokenJson = JSON.parse(text);
  } catch (e) {
    console.error("MP token exchange exception:", e);
    return htmlResponse(
      errorPage("Error de red", "No pudimos comunicarnos con Mercado Pago."),
      502,
    );
  }

  // ----- 4. Guardar tokens en mp_accounts (upsert por business_id) -----
  const expiresAt = new Date(
    Date.now() + Number(tokenJson.expires_in ?? 0) * 1000,
  ).toISOString();

  const { error: upsertErr } = await admin.from("mp_accounts").upsert(
    {
      business_id: stateRow.business_id,
      mp_user_id: String(tokenJson.user_id),
      public_key: tokenJson.public_key ?? null,
      live_mode: !!tokenJson.live_mode,
      scope: tokenJson.scope ?? null,
      access_token: tokenJson.access_token,
      refresh_token: tokenJson.refresh_token,
      expires_at: expiresAt,
      last_refreshed_at: new Date().toISOString(),
    },
    { onConflict: "business_id" },
  );

  if (upsertErr) {
    console.error("mp_accounts upsert failed:", upsertErr);
    // Caso especial: el mp_user_id ya está conectado a OTRO business
    if (upsertErr.code === "23505") {
      return htmlResponse(
        errorPage(
          "Cuenta ya conectada",
          "Esta cuenta de Mercado Pago ya está vinculada a otro negocio en CONOCEMEX.",
        ),
        409,
      );
    }
    return htmlResponse(
      errorPage(
        "Error guardando",
        "No pudimos guardar tu cuenta. Inténtalo de nuevo.",
      ),
      500,
    );
  }

  // ----- 5. Éxito -----
  return htmlResponse(successPage(), 200);
});
