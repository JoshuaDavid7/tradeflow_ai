# Stripe Secure Payments (TradeFlow AI)

This repo now includes a Stripe-hosted checkout flow for invoices:

- `create_stripe_checkout` Supabase Edge Function (JWT-protected)
- `stripe_webhook` Supabase Edge Function (Stripe signature verified)
- PDF payment instructions support (secure link + QR code)
- Job payment metadata persistence and webhook event idempotency table

## 1. Run the database migration

Apply:

- `supabase/migrations/20260225_secure_payments_and_client_contacts.sql`

This adds:

- client contact fields on `jobs` (`client_address`, `client_phone`, `client_email`)
- payment checkout tracking fields on `jobs`
- `stripe_webhook_events` table for webhook idempotency

## 2. Configure Stripe

In Stripe Dashboard:

1. Enable the payment methods you want to support (start with card; add others after testing).
2. Create a webhook endpoint pointing to your Supabase function URL:
   - `https://<PROJECT-REF>.functions.supabase.co/stripe_webhook`
3. Subscribe to at least:
   - `checkout.session.completed`
   - `checkout.session.async_payment_succeeded`
   - `checkout.session.async_payment_failed`
   - `checkout.session.expired`
4. Copy the webhook signing secret (`whsec_...`).

## 3. Set Supabase Edge Function secrets

Set these secrets in Supabase:

- `STRIPE_SECRET_KEY` = your Stripe secret key (`sk_live_...` / `sk_test_...`)
- `STRIPE_WEBHOOK_SECRET` = webhook signing secret (`whsec_...`)
- `STRIPE_CHECKOUT_SUCCESS_URL` = URL or deep link after payment
- `STRIPE_CHECKOUT_CANCEL_URL` = URL or deep link if customer cancels

Optional:

- `STRIPE_CHECKOUT_PAYMENT_METHOD_TYPES` = comma-separated list (example: `card`)
- `STRIPE_WEBHOOK_TOLERANCE_SECONDS` = default `300`

Notes:

- Keep secrets server-side only (never in Flutter `.env` files).
- `STRIPE_CHECKOUT_SUCCESS_URL` will automatically receive `session_id={CHECKOUT_SESSION_ID}` if not already present.

## 4. Deploy Supabase functions

Deploy:

- `supabase functions deploy create_stripe_checkout`
- `supabase functions deploy stripe_webhook`

Verify `supabase/config.toml` includes:

- `[functions.create_stripe_checkout] verify_jwt = true`
- `[functions.stripe_webhook] verify_jwt = false`

## 5. App flow (what users now do)

In the invoice worksheet:

1. Enter client name/contact info
2. Tap `SECURE PAY LINK + PDF (STRIPE)`
3. App saves/updates the draft job
4. App creates a Stripe-hosted checkout session
5. PDF is generated with:
   - secure payment link
   - QR code
   - optional template payment terms

## 6. Security checklist (production)

- Use Stripe **test mode** first and validate webhook updates on job status.
- Confirm webhook endpoint uses the correct `whsec_...` (test vs live differ).
- Do not mark invoices as paid from the client app; rely on webhook status updates.
- Restrict who can update/read `jobs` with proper RLS policies (if not already configured).
- Rotate webhook secrets/Stripe keys if they were ever exposed.

## 7. Testing checklist

- Create secure checkout from an invoice and confirm:
  - PDF contains clickable link + QR code
  - `jobs.payment_checkout_session_id` and `jobs.payment_checkout_url` are stored
- Complete payment in Stripe test mode and verify webhook updates:
  - `jobs.payment_status = 'paid'`
  - `jobs.status = 'paid'`
  - `jobs.payment_paid_at` set

