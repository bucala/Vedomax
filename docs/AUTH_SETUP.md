# Email delivery and Google login

Deployment: https://vedomax.web.app. Supabase project: uifthknpirbcexiqeqmx. Authentication remains in Supabase; do not enable a separate Firebase Auth user store for this flow.

## Missing confirmation email

First inspect Supabase Authentication → Users for the registration and Auth logs at the relevant time. Do not share user records, full email addresses, tokens or complete logs. Check spam, then identify the actual delivery error before retrying.

Supabase's default mail service only delivers to project team member addresses, has low shared sending limits and no delivery SLA. This is documented at https://supabase.com/docs/guides/auth/auth-smtp. A public student application needs custom SMTP under Supabase Authentication → SMTP Settings (https://supabase.com/dashboard/project/uifthknpirbcexiqeqmx/auth/smtp). Choose a mail provider, verify your sending domain and configure SPF/DKIM/DMARC using the provider's exact instructions. Enter SMTP credentials only in Supabase settings, never the app or chat. Keep email confirmation enabled. A resend button cannot fix missing SMTP configuration or bypass rate limits.

The new app version offers confirmation resend and sanitized messages for mail restrictions/rate limits. Some server-side delivery errors still require Auth-log diagnosis; no successful registration or delivery has been independently confirmed in this task. Google login normally relies on Google's verified email and does not need a Supabase confirmation email; password resets and email-based operations still need working mail.

## Google OAuth web configuration

1. Open Google Cloud Console / Google Auth Platform in the existing Firebase project **vedomax**: https://console.cloud.google.com/auth/overview?project=vedomax.
2. Configure Branding (Vedomax, support/developer contact) and Audience. For a public app choose External; initially use Testing and add only your own test account. School Workspace domains may require administrator approval, particularly for minors. Publish the consent configuration before inviting general users; supply real privacy information and any domain verification Google requests.
3. Create an OAuth client of type **Web application** under Clients. A Firebase web API key is not an OAuth client ID.
4. Authorized JavaScript origin: `https://vedomax.web.app` (no slash/path).
5. Authorized redirect URI: `https://uifthknpirbcexiqeqmx.supabase.co/auth/v1/callback`. This is the Supabase callback, not the Firebase home page. Copy the callback from the Supabase provider panel if in doubt.
6. In Supabase Authentication → Sign In / Providers → Google, enable the provider. Copy the Web OAuth Client ID and Client Secret from Google into the corresponding Supabase fields. Keep **Skip nonce checks OFF**. For this ordinary Google flow keep **Allow users without an email OFF**; that switch does not remove email/profile permission scopes.
7. In Supabase Authentication → URL Configuration, Site URL is `https://vedomax.web.app`, and the exact return URL `https://vedomax.web.app/` is allowlisted. Avoid production wildcard redirect URLs.
8. Save, publish the updated Flutter web build and use its new “Pokračovať cez Google” button. The client uses PKCE, a fixed allowlisted return URL and no extra OAuth scopes or offline-access request. Native Android/iOS Google login remains disabled until native redirects are configured.

Do not paste the Client Secret in chat, source files, Firebase Hosting assets or Git. It belongs in Supabase's server-side provider configuration. No Gmail/Drive/Calendar API is needed.

## What user information is processed

The standard Supabase Google OAuth provider requests `email` and `profile` by default, even if the frontend supplies no extra scopes. Setting `scopes: 'openid email'` in Flutter would not remove these defaults. Verified against the provider implementation at https://github.com/supabase/auth/blob/master/internal/api/provider/google.go.

Supabase Auth may retain the email, provider identifier, name/photo and related claims in its protected auth user/identity metadata. Do not claim that Google login is anonymous or that the whole backend stores only a UUID. Turning off “Allow users without an email” does not change requested scopes.

The application's existing auth trigger deliberately creates only a UUID-linked generated nickname in `public.profiles`; it does not copy the Google name, email or avatar. Leaderboard visibility defaults to false. The application does not request birth date, phone, contacts, school, location, Gmail, Drive or Calendar access. Do not add offline access, analytics, Google provider-token storage or user-metadata logging without a concrete requirement and review. Supabase session handling remains in the SDK, and web sessions can persist in browser storage; users should sign out on shared devices. This Flutter SPA does not provide HttpOnly cookie isolation for tokens.

Before student rollout, complete the privacy notice, retention/account deletion workflow and the consent/school policy appropriate for this age group. No full regulatory or classroom-release readiness is claimed by this MVP.

## Acceptance checks

- In a private browser window, open the published site and use Google login with the configured test account; verify account selection, provider consent and return to the same site.
- Cancel Google authorization and check that the app does not report a successful login. If Google rejects the client, verify client ID, redirect URI and test-user audience first.
- On successful login, inspect your own profile: generated nickname, no copied Google name/avatar, zero initial XP, leaderboard off. Complete a lesson, reload and verify persisted XP.
- Verify logout on a shared device and isolation of profile/progression between two authorized test accounts.
- After SMTP setup, use the app's resend button for your own account, check delivery, open the confirmation link in the initiating browser where possible, and verify login. Do not repeatedly resend while rate limited.

Automated tests validate widget behavior and failure mapping, not the Google console configuration, actual OAuth callback, SMTP delivery or Google/Supabase account metadata contents in the live project.

## Silent OAuth return diagnostic update

The previous SDK-managed web callback could emit an initialization error before the application's Riverpod auth listener existed. The auth gate also rendered stream errors as a plain login screen. This explains how an error could be hidden; it does not establish the live OAuth configuration's underlying failure.

For web, automatic URI detection is now disabled and the app explicitly awaits the SDK's `getSessionFromUrl` once before opening the auth gate. Native SDK URI handling is unchanged. The exchange uses the existing PKCE verifier and normal SDK session storage; verification is not disabled. A loading view and a 20-second response timeout make progress/failure visible. One-use codes and error parameters are removed from browser history without logging them. Session listeners subscribe before taking the initial snapshot.

The app requires Google login to start on the configured return origin (`https://vedomax.web.app` by default), so a login started on the Firebase alias or another origin cannot silently lose access to its browser-local PKCE verifier. Use the same browser/profile/window for start and return. For deliberately configured local development, set an explicit AUTH_REDIRECT_URL and allowlist it in Supabase.

Displayed diagnostic categories are fixed strings, not raw provider payloads: AUTH-ORIGIN, AUTH-OAUTH, AUTH-PKCE, AUTH-EXCHANGE, AUTH-TIMEOUT, AUTH-CONNECTION and AUTH-CANCELLED. The caller should report only that category and redacted Auth-log error codes, never callback URLs, authorization codes or tokens. Real Google login still requires a user-side acceptance test after deployment.
