# Authentication Setup (Launch)

This app now supports:

- Email + password
- Email magic link
- Google OAuth
- Apple OAuth

Phone OTP is intentionally deferred for initial launch.

## 1. Supabase Auth Providers

In Supabase Dashboard -> Authentication -> Providers:

1. Enable `Email`
2. Enable `Google`
3. Enable `Apple` (recommended/required for iOS if other social logins are offered)

## 2. Redirect URL

The app uses this mobile callback by default:

- `siteinvoiceai://login-callback/`

Set this URL in:

1. Supabase Auth -> URL Configuration -> Additional Redirect URLs
2. OAuth provider dashboards (Google/Apple), where callback allowlists are required

If you want a different redirect URI, update:

- `.env.development` -> `AUTH_REDIRECT_URL`
- `.env.production` -> `AUTH_REDIRECT_URL`
- iOS URL scheme in `ios/Runner/Info.plist` (must match scheme)

## 3. iOS URL Scheme

`Info.plist` includes:

- `CFBundleURLSchemes` -> `siteinvoiceai`

If you change `AUTH_REDIRECT_URL`, keep the scheme aligned.

## 4. Google Provider Notes

In Google Cloud Console, configure OAuth consent and callback URLs required by Supabase.

Then copy Google client ID/secret into Supabase Google provider settings.

## 5. Apple Provider Notes

Create an Apple Sign In key/cert setup and configure Service ID / redirect URLs per Supabase docs.

Then copy credentials to Supabase Apple provider settings.

## 6. Email / Magic Link Behavior

- Email/password works directly in app.
- Magic link sends an email to the entered address.
- User must open the link on a device that can route back to this app scheme.

