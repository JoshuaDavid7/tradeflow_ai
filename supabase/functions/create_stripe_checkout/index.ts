import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function json(
  body: Record<string, unknown>,
  status = 200,
  extraHeaders: Record<string, string> = {},
) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
      ...extraHeaders,
    },
  });
}

function getRequiredEnv(key: string): string {
  const value = Deno.env.get(key)?.trim();
  if (!value) throw new Error(`Missing required environment variable: ${key}`);
  return value;
}

function sanitizeCurrency(value: unknown): string {
  const v = String(value ?? "usd").trim().toLowerCase();
  if (!/^[a-z]{3}$/.test(v)) return "usd";
  return v;
}

function sanitizeMethodsCsv(value: string | undefined): string[] {
  if (!value) return ["card"];
  const methods = value
    .split(",")
    .map((m) => m.trim().toLowerCase())
    .filter((m) => /^[a-z_]+$/.test(m));
  return methods.length > 0 ? [...new Set(methods)] : ["card"];
}

function withSessionPlaceholder(url: string): string {
  if (url.includes("{CHECKOUT_SESSION_ID}")) return url;
  const separator = url.includes("?") ? "&" : "?";
  return `${url}${separator}session_id={CHECKOUT_SESSION_ID}`;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  try {
    const authHeader =
      req.headers.get("authorization") ?? req.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return json({ error: "Missing bearer token" }, 401);
    }
    const jwt = authHeader.slice("Bearer ".length).trim();

    const body = await req.json();
    const amountMinor = Number(body?.amountMinor ?? 0);
    const currency = sanitizeCurrency(body?.currency);
    const clientName = String(body?.clientName ?? "Customer").trim() || "Customer";
    const clientEmail = String(body?.clientEmail ?? "").trim();
    const documentType =
      String(body?.documentType ?? "invoice").trim().toLowerCase() || "invoice";
    const description = String(body?.description ?? "").trim();
    const jobId = String(body?.jobId ?? "").trim();

    if (!Number.isFinite(amountMinor) || amountMinor <= 0) {
      return json({ error: "amountMinor must be a positive integer" }, 400);
    }

    const stripeSecretKey = getRequiredEnv("STRIPE_SECRET_KEY");
    const successUrl = withSessionPlaceholder(
      getRequiredEnv("STRIPE_CHECKOUT_SUCCESS_URL"),
    );
    const cancelUrl = getRequiredEnv("STRIPE_CHECKOUT_CANCEL_URL");
    const paymentMethodTypes = sanitizeMethodsCsv(
      Deno.env.get("STRIPE_CHECKOUT_PAYMENT_METHOD_TYPES") ?? undefined,
    );

    const supabaseUrl = getRequiredEnv("SUPABASE_URL");
    const supabaseServiceRoleKey = getRequiredEnv("SUPABASE_SERVICE_ROLE_KEY");
    const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

    // Gateway-level JWT verification is incompatible with publishable-key
    // projects in some Supabase setups, so we verify the bearer token here.
    const { data: authData, error: authError } = await supabase.auth.getUser(jwt);
    if (authError || !authData.user?.id) {
      console.error("JWT verification failed in create_stripe_checkout", authError);
      return json({ error: "Invalid JWT" }, 401);
    }
    const userId = authData.user.id;

    if (jobId) {
      const { data: job, error: jobError } = await supabase
        .from("jobs")
        .select("id,user_id,total_amount,status,type")
        .eq("id", jobId)
        .maybeSingle();

      if (jobError) {
        throw new Error(`Failed to verify job ownership: ${jobError.message}`);
      }
      if (!job) {
        return json({ error: "Job not found" }, 404);
      }
      if (job.user_id !== userId) {
        return json({ error: "You do not have access to this job" }, 403);
      }
    }

    const form = new URLSearchParams();
    form.append("mode", "payment");
    form.append("success_url", successUrl);
    form.append("cancel_url", cancelUrl);
    form.append("line_items[0][quantity]", "1");
    form.append("line_items[0][price_data][currency]", currency);
    form.append("line_items[0][price_data][unit_amount]", `${Math.round(amountMinor)}`);
    form.append(
      "line_items[0][price_data][product_data][name]",
      `TradeFlow ${documentType.toUpperCase()} Payment`,
    );
    if (description) {
      form.append(
        "line_items[0][price_data][product_data][description]",
        description.slice(0, 500),
      );
    } else {
      form.append(
        "line_items[0][price_data][product_data][description]",
        `Secure payment requested by ${clientName}`,
      );
    }
    for (let i = 0; i < paymentMethodTypes.length; i++) {
      form.append(`payment_method_types[${i}]`, paymentMethodTypes[i]);
    }
    form.append("client_reference_id", jobId || `tradeflow-${userId}-${Date.now()}`);
    form.append("metadata[user_id]", userId);
    form.append("metadata[document_type]", documentType);
    if (jobId) form.append("metadata[job_id]", jobId);
    form.append("metadata[source]", "tradeflow_ai");
    if (clientEmail) form.append("customer_email", clientEmail);
    if (jobId) form.append("payment_intent_data[metadata][job_id]", jobId);
    form.append("payment_intent_data[metadata][user_id]", userId);
    form.append("payment_intent_data[metadata][source]", "tradeflow_ai");

    const stripeRes = await fetch("https://api.stripe.com/v1/checkout/sessions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${stripeSecretKey}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: form.toString(),
    });

    const stripeJson = await stripeRes.json();
    if (!stripeRes.ok) {
      console.error("Stripe checkout session error", stripeJson);
      return json(
        {
          error: "Stripe checkout session creation failed",
          details: stripeJson?.error?.message ?? stripeJson,
        },
        502,
      );
    }

    const sessionId = String(stripeJson.id ?? "");
    const checkoutUrl = String(stripeJson.url ?? "");
    const expiresAtEpoch = Number(stripeJson.expires_at ?? 0);
    const expiresAtIso = Number.isFinite(expiresAtEpoch) && expiresAtEpoch > 0
      ? new Date(expiresAtEpoch * 1000).toISOString()
      : null;

    if (!sessionId || !checkoutUrl) {
      return json({ error: "Stripe response missing checkout URL" }, 502);
    }

    if (jobId) {
      const updatePayload: Record<string, unknown> = {
        payment_provider: "stripe",
        payment_checkout_url: checkoutUrl,
        payment_checkout_session_id: sessionId,
        payment_status: "pending",
        payment_currency: currency,
        payment_amount_minor: Math.round(amountMinor),
        secure_payment_methods: paymentMethodTypes,
      };
      if (expiresAtIso) {
        updatePayload.payment_checkout_expires_at = expiresAtIso;
      }

      const { error: updateError } = await supabase
        .from("jobs")
        .update(updatePayload)
        .eq("id", jobId)
        .eq("user_id", userId);

      if (updateError) {
        console.error("Failed to persist checkout session to jobs", updateError);
        // Session is created successfully; return the link anyway but flag persistence issue.
        return json({
          provider: "stripe",
          checkoutUrl,
          checkoutSessionId: sessionId,
          currency,
          amountMinor: Math.round(amountMinor),
          acceptedMethods: paymentMethodTypes,
          expiresAt: expiresAtIso,
          persistenceWarning: updateError.message,
        });
      }
    }

    return json({
      provider: "stripe",
      checkoutUrl,
      checkoutSessionId: sessionId,
      currency,
      amountMinor: Math.round(amountMinor),
      acceptedMethods: paymentMethodTypes,
      expiresAt: expiresAtIso,
    });
  } catch (error) {
    console.error("create_stripe_checkout failed", error);
    return json(
      { error: error instanceof Error ? error.message : String(error) },
      500,
    );
  }
});
