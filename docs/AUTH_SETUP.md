# Email-only authentication

The current application uses Supabase email/password authentication. Google sign-in has been removed at the user's request. Firebase Hosting still serves the Flutter web app; Supabase remains the auth/database backend.

## Required Supabase settings

1. Authentication → Sign In / Providers → Google: turn **Enable Sign in with Google OFF**, then **Save**. This administrative change has not been executed by the agent; it requires the project owner's dashboard access. Removing the app button alone does not disable the provider's API.
2. Keep the Email provider enabled and email confirmation enabled.
3. URL Configuration: Site URL `https://vedomax.web.app`, with `https://vedomax.web.app/` allowed as the confirmation return URL.
4. Configure a custom SMTP provider at https://supabase.com/dashboard/project/uifthknpirbcexiqeqmx/auth/smtp. Enter only the settings given by the selected mail provider: host, port, username, password and verified sender address/name. Store SMTP secrets in Supabase settings only, never in chat, app source or Firebase assets.

## Missing confirmation mail

Supabase's built-in mail service delivers only to addresses belonging to members of the project's team and has low sending limits. Public student registrations need custom SMTP. See https://supabase.com/docs/guides/auth/auth-smtp. We have not read this project's private SMTP settings or delivery logs, so its exact delivery failure is still unconfirmed.

Use a provider such as Resend, Brevo, Postmark or an existing transactional SMTP service. Verify the sender/domain and SPF/DKIM/DMARC using that provider's instructions. Configure its credentials securely in Supabase. Confirmation resend cannot bypass missing sender configuration or rate limits. It does not guarantee delivery merely because the app says the request was accepted.

If custom SMTP is already configured, inspect Supabase Auth logs around the registration/resend attempt and the mail provider's delivery logs. Check spam, sender verification, credentials, provider restrictions, bounce/suppression lists and rate limits. Share only a redacted error code/message; never share whole auth URLs, tokens, SMTP passwords or complete user records.

After settings are saved, use the updated app to register your own test account or resend confirmation for your existing unconfirmed account. Open the newest confirmation link in the browser where registration started when possible, then sign in and verify persistent XP after a lesson. The app allows existing nonempty passwords on login; new registrations require at least eight characters. The server's password policy should be configured consistently in Supabase.

## Accounts and data

This update does not delete auth accounts, profiles or game progression. Disabling the Google provider prevents future Google sign-ins; previously Google-only users would need a properly delivered password-reset flow to establish a password. A password recovery UI is not implemented in this MVP.

The application profile uses the user UUID and a generated nickname. Authentication still stores the email address and account/session data in Supabase; email login is not anonymous. Old Google-linked users may retain existing provider metadata unless separately reviewed. Do not delete users or metadata merely to remove a sign-in button.

## Confirmation return handling

The app explicitly completes web confirmation callbacks using the SDK's PKCE exchange and session storage, with a loading view, timeout and sanitized errors. Native URI handling is unchanged. Query/fragment auth parameters are removed from history after processing without being logged. Session listeners subscribe before reading their initial user snapshot.

Diagnostic codes include AUTH-LINK, AUTH-PKCE, AUTH-EXCHANGE, AUTH-TIMEOUT, AUTH-CONNECTION, AUTH-CANCELLED and MAIL-SETUP. They identify a category, not the exact server-side cause. No Google client/secret is required by the email-only app.

## Current validation boundary

Automated tests cover email login, registration validation, confirmation guidance, resend, safe error mapping, confirmation return handling and gameplay. They do not confirm SMTP delivery or real-user authentication on the hosted project. No test emails or accounts were created by the agent.
