# Accounts in Flutter Vedomax 2

Email/password login uses `supabase_flutter`, PKCE and SDK session persistence/confirmation returns. Restored sessions are read at startup. Profiles and leaderboards come from Supabase, never mock browser accounts. Pupil-facing errors omit raw server payloads.

Configuration uses `SUPABASE_URL` and `SUPABASE_ANON_KEY` in ignored `.env.supabase.json`, passed through `--dart-define-from-file`. The latter name is retained for compatibility; the prepared configuration uses a **publishable** key. No service-role credential belongs here.

In Supabase Authentication:

1. Enable email sign-in and set the Site URL to the deployed application URL.
2. Allow exact confirmation callback URLs, including local development when needed.
3. Configure custom SMTP and verified sender/domain details for public registration. Diagnose missing emails through Auth and provider delivery logs.
4. Retain email confirmation. The UI offers resend, accepts existing nonempty passwords, and requires eight characters for new registrations.

References: [password login](https://supabase.com/docs/reference/dart/auth-signinwithpassword), [SMTP](https://supabase.com/docs/guides/auth/auth-smtp), [redirect URLs](https://supabase.com/docs/guides/auth/redirect-urls).

No emails were sent or permanent test accounts created. Hosted SQL tests insert identities and roll back the entire transaction. They validate permissions and grading, not SMTP or browser login.

The React prototype's local password accounts are disabled and plaintext credential keys are removed on web startup. Guest progress is separate; it is not imported into an authenticated leaderboard. Existing Supabase users, profiles and scores were not deleted.

Leaderboard participation defaults to false and requires opt-in. Only nickname and XP are exposed; no fabricated entries are shown.
