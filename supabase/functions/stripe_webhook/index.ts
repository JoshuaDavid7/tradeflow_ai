import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type StripeEvent = {
  id: string;
  type: string;
  livemode?: boolean;
  data?: { object?: Record<string, unknown> };
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, stripe-signature",
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

function parseStripeSignature(header: string): {
  timestamp: number;
  v1Signatures: string[];
} {
  const parts = header.split(",").map((p) => p.trim());
  let timestamp = 0;
  const v1Signatures: string[] = [];

  for (const part of parts) {
    const [key, ...rest] = part.split("=");
    const value = rest.join("=");
    if (!key || !value) continue;
    if (key === "t") {
      timestamp = Number(value);
    } else if (key === "v1") {
      v1Signatures.push(value);
    }
  }

  if (!timestamp || v1Signatures.length === 0) {
    throw new Error("Invalid Stripe-Signature header");
  }

  return { timestamp, v1Signatures };
}

function hexToBytes(hex: string): Uint8Array {
  const clean = hex.trim().toLowerCase();
  if (clean.length % 2 !== 0) throw new Error("Invalid hex length");
  const bytes = new Uint8Array(clean.length / 2);
  for (let i = 0; i < clean.length; i += 2) {
    bytes[i / 2] = parseInt(clean.slice(i, i + 2), 16);
  }
  return bytes;
}

function bytesToHex(bytes: Uint8Array): string {
  return Array.from(bytes).map((b) => b.toString(16).padStart(2, "0")).join("");
}

function timingSafeEqualHex(a: string, b: string): boolean {
  const aBytes = hexToBytes(a);
  const bBytes = hexToBytes(b);
  if (aBytes.length !== bBytes.length) return false;
  let diff = 0;
  for (let i = 0; i < aBytes.length; i++) diff |= aBytes[i] ^ bBytes[i];
  return diff === 0;
}

async function computeStripeSignatureHex(
  secret: string,
  signedPayload: string,
): Promise<string> {
  const enc = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    enc.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", key, enc.encode(signedPayload));
  return bytesToHex(new Uint8Array(sig));
}

async function verifyStripeSignature(opts: {
  payload: string;
  signatureHeader: string;
  secrets: string[];
  toleranceSeconds: number;
}) {
  const { timestamp, v1Signatures } = parseStripeSignature(opts.signatureHeader);
  const now = Math.floor(Date.now() / 1000);
  if (Math.abs(now - timestamp) > opts.toleranceSeconds) {
    throw new Error("Webhook signature timestamp outside tolerance window");
  }

  const signedPayload = `${timestamp}.${opts.payload}`;
  for (const secret of opts.secrets) {
    const expected = await computeStripeSignatureHex(secret, signedPayload);
    for (const provided of v1Signatures) {
      if (timingSafeEqualHex(expected, provided)) {
        return;
      }
    }
  }
  throw new Error("Stripe webhook signature verification failed");
}

function getString(obj: Record<string, unknown>, key: string): string {
  const value = obj[key];
  return typeof value === "string" ? value : "";
}

function getNumber(obj: Record<string, unknown>, key: string): number | null {
  const value = obj[key];
  if (typeof value === "number" && Number.isFinite(value)) return value;
  return null;
}

function getMetadata(obj: Record<string, unknown>): Record<string, unknown> {
  const raw = obj["metadata"];
  return raw && typeof raw === "object" ? (raw as Record<string, unknown>) : {};
}

async function fetchStripeCheckoutSession(
  sessionId: string,
): Promise<Record<string, unknown> | null> {
  const stripeSecretKey = Deno.env.get("STRIPE_SECRET_KEY")?.trim();
  if (!stripeSecretKey || !sessionId.trim()) return null;

  try {
    const res = await fetch(
      `https://api.stripe.com/v1/checkout/sessions/${encodeURIComponent(sessionId)}`,
      {
        method: "GET",
        headers: {
          Authorization: `Bearer ${stripeSecretKey}`,
        },
      },
    );

    const json = await res.json();
    if (!res.ok) {
      console.error("Failed to hydrate checkout session from Stripe", {
        sessionId,
        status: res.status,
        body: json,
      });
      return null;
    }

    return json && typeof json === "object" ? (json as Record<string, unknown>) : null;
  } catch (error) {
    console.error("Stripe checkout session hydration error", { sessionId, error });
    return null;
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  try {
    const signatureHeader = req.headers.get("stripe-signature");
    if (!signatureHeader) return json({ error: "Missing Stripe-Signature" }, 400);

    const rawBody = await req.text();

    const webhookSecrets = (
      Deno.env.get("STRIPE_WEBHOOK_SECRETS") ?? Deno.env.get("STRIPE_WEBHOOK_SECRET") ?? ""
    )
      .split(",")
      .map((s) => s.trim())
      .filter(Boolean);

    if (webhookSecrets.length === 0) {
      throw new Error(
        "Missing STRIPE_WEBHOOK_SECRET or STRIPE_WEBHOOK_SECRETS environment variable",
      );
    }

    const toleranceSeconds = Number(
      Deno.env.get("STRIPE_WEBHOOK_TOLERANCE_SECONDS") ?? "300",
    );

    await verifyStripeSignature({
      payload: rawBody,
      signatureHeader,
      secrets: webhookSecrets,
      toleranceSeconds: Number.isFinite(toleranceSeconds) ? toleranceSeconds : 300,
    });

    const event = JSON.parse(rawBody) as StripeEvent;
    if (!event?.id || !event?.type) {
      return json({ error: "Invalid Stripe event payload" }, 400);
    }

    const supabaseUrl = getRequiredEnv("SUPABASE_URL");
    const supabaseServiceRoleKey = getRequiredEnv("SUPABASE_SERVICE_ROLE_KEY");
    const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

    let duplicateEvent = false;
    const { error: webhookInsertError } = await supabase
      .from("stripe_webhook_events")
      .insert({
        id: event.id,
        event_type: event.type,
        livemode: event.livemode ?? null,
        payload: event as unknown as Record<string, unknown>,
      });

    if (webhookInsertError) {
      // PostgreSQL unique violation = duplicate event (idempotent success)
      if ((webhookInsertError as { code?: string }).code === "23505") {
        duplicateEvent = true;
      } else {
        throw new Error(`Failed to record webhook event: ${webhookInsertError.message}`);
      }
    }

    let object = (event.data?.object ?? {}) as Record<string, unknown>;
    let sessionId = getString(object, "id");

    // Some Stripe event destinations send thinner checkout.session payloads.
    // Hydrate the full Checkout Session so metadata/payment_status is reliable.
    if (event.type.startsWith("checkout.session.") && sessionId) {
      const hasPaymentStatus = getString(object, "payment_status").length > 0;
      const hasMetadata = Object.keys(getMetadata(object)).length > 0;
      if (!hasPaymentStatus || !hasMetadata) {
        const hydrated = await fetchStripeCheckoutSession(sessionId);
        if (hydrated != null) {
          object = hydrated;
          sessionId = getString(object, "id") || sessionId;
        }
      }
    }

    const metadata = getMetadata(object);
    const metadataJobId = String(metadata["job_id"] ?? "").trim();

    const update: Record<string, unknown> = {
      payment_provider: "stripe",
      last_payment_event_id: event.id,
    };

    const paymentStatus = getString(object, "payment_status");
    const amountTotal = getNumber(object, "amount_total");
    const currency = getString(object, "currency").toLowerCase();
    const expiresAt = getNumber(object, "expires_at");

    if (sessionId) update.payment_checkout_session_id = sessionId;
    if (paymentStatus) update.payment_status = paymentStatus;
    if (amountTotal != null) update.payment_amount_minor = Math.round(amountTotal);
    if (currency) update.payment_currency = currency;
    if (expiresAt != null && expiresAt > 0) {
      update.payment_checkout_expires_at = new Date(expiresAt * 1000).toISOString();
    }

    const eventType = event.type;
    const marksPaid =
      (eventType === "checkout.session.completed" &&
        (paymentStatus === "paid" || paymentStatus === "")) ||
      eventType === "checkout.session.async_payment_succeeded";
    const marksFailed = eventType === "checkout.session.async_payment_failed";
    const marksExpired = eventType === "checkout.session.expired";

    if (marksPaid) {
      update.payment_status = "paid";
      update.payment_paid_at = new Date().toISOString();
      update.status = "paid";
    } else if (marksFailed) {
      update.payment_status = "failed";
    } else if (marksExpired) {
      update.payment_status = "expired";
    }

    // Only update jobs for checkout session events (other event types are acknowledged)
    if (eventType.startsWith("checkout.session.")) {
      if (!metadataJobId && !sessionId) {
        return json({ received: true, ignored: "No job_id or session id" });
      }

      let updated = false;

      if (metadataJobId) {
        const { data: byId, error: byIdError } = await supabase
          .from("jobs")
          .update(update)
          .eq("id", metadataJobId)
          .select("id");

        if (byIdError) {
          throw new Error(`Failed to update job by id: ${byIdError.message}`);
        }
        updated = (byId?.length ?? 0) > 0;
      }

      // Fallback when metadata job_id is missing/stale: match by checkout session id.
      if (!updated && sessionId) {
        const { data: bySession, error: bySessionError } = await supabase
          .from("jobs")
          .update(update)
          .eq("payment_checkout_session_id", sessionId)
          .select("id");

        if (bySessionError) {
          throw new Error(
            `Failed to update job by checkout session id: ${bySessionError.message}`,
          );
        }
        updated = (bySession?.length ?? 0) > 0;
      }

      if (!updated) {
        throw new Error(
          `Webhook event could not be matched to a job (event=${event.id}, metadata_job_id=${metadataJobId || "none"}, session_id=${sessionId || "none"})`,
        );
      }
    }

    return json({ received: true, duplicate: duplicateEvent });
  } catch (error) {
    console.error("stripe_webhook failed", error);
    return json(
      { error: error instanceof Error ? error.message : String(error) },
      400,
    );
  }
});
