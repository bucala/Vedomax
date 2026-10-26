# Vedomax

Flutter / Riverpod / Supabase MVP for Slovak pupils in grades 8–9. Includes a playable, account-free demo, authenticated mode, three practice mechanics, server-graded XP, streaks, private profiles, progression and an opt-in leaderboard RPC.

**Status:** Flutter dependencies are installed, static analysis is clean and all ten tests pass. Hosted Supabase connectivity and authentication remain unverified because the project domain is pending network approval. Validation results and limitations are recorded in `docs/VALIDATION.md`. Sample curriculum is a **draft**, not a claim of NIVAM certification or complete iŠVP coverage.

## Run

Use Flutter **3.38.5** (Dart 3.10), Git and an Android SDK/JDK for Android; macOS/Xcode is required for iOS. Web is the cloud smoke-test target; no Android emulator is required for it.

```sh
export PATH="/workspace/toolchains/flutter/bin:$PATH"
export PUB_CACHE=/workspace/toolchains/pub-cache
export XDG_CONFIG_HOME=/workspace/toolchains/config
export ANALYZER_STATE_LOCATION_OVERRIDE=/workspace/toolchains/analyzer-state
cd /workspace/Vedomax
./scripts/bootstrap.sh
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080 --dart-define=DEMO_MODE=true
```

The bootstrap script generates missing Android/iOS platform shells in a temporary project and copies only missing platform directories. The resolved `pubspec.lock` is committed. Review and commit generated platform files in the coding workflow. Subsequent installs enforce that lockfile. It does not rewrite Dart source. A demo opens three lessons; XP remains zero and no account or network backend is used. Theme follows system dark/light preferences. The original bundled Lottie star needs no remote asset fetch. Reduced-motion preference disables its playback.

For a device: run `flutter devices`, then `flutter run -d <device-id>`. Android/iOS signing, store IDs, deep links and release distribution are separate release steps.

## Supabase

Create a development Supabase project. Apply `supabase/migrations/202610260001_core.sql` in the SQL editor or via Supabase CLI, then `supabase/seed.sql`. Seeds are repeatable and preserve existing rows. Enable email/password auth with email confirmation; configure redirect allowlists and SMTP in Supabase. Profiles are created by the auth trigger. Never put a service-role key in the app.

```sh
flutter run -d <device-id> \
  --dart-define=DEMO_MODE=false \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_PUBLISHABLE_OR_ANON_KEY
```

For this workspace, the supplied project connection is stored in `.env.supabase.json` (ignored by Git). Run it without putting the key in a shell command:

```sh
export PATH="/workspace/toolchains/flutter/bin:$PATH"
export PUB_CACHE=/workspace/toolchains/pub-cache
export XDG_CONFIG_HOME=/workspace/toolchains/config
export ANALYZER_STATE_LOCATION_OVERRIDE=/workspace/toolchains/analyzer-state
./scripts/run_supabase.sh -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

Project: `uifthknpirbcexiqeqmx`. The configuration file must contain `DEMO_MODE: false`, `SUPABASE_URL` and `SUPABASE_ANON_KEY`. It is local configuration and will not be available from a fresh Git clone; supply these fields there before running the helper. A publishable key authenticates the application, not an administrator, and cannot apply SQL migrations.

The URL and publishable/anon key are public client configuration. User JWTs supply access; RLS is essential. Do not commit private credentials or session tokens. Live signup, confirmation, login, logout and XP sync require your configured project and remain integration checks.

Global content is read-only to authenticated clients. Users read only their own profile/progression and can update their username/avatar/leaderboard consent. **Progression writes go through `begin_lesson` / `submit_lesson`**, rather than direct table updates. The server owns XP, streak and high score; improving a best score earns only its delta. Repeat completion cannot farm XP. Attempts expire by server time; five seconds allow submission transit. Starting again replaces that user's existing attempt for the lesson. Concurrent tabs are not independent attempts.

`leaderboard()` exposes only opted-in pseudonyms and XP (top 50); full profiles remain private. The initial UI includes profile loading and XP refresh after completion; profile editing and leaderboard UI are roadmap items. Public practice hints (detective feedback) are intentionally available; this is not a proctored exam/anti-bot system.

## Google sign-in and confirmation email

See [AUTH_SETUP.md](docs/AUTH_SETUP.md) for exact Google OAuth origins/callbacks, the two provider switches, SMTP diagnosis and data minimization limits. The web login now includes Google OAuth (PKCE, no additional scopes), confirmation resend and sanitized delivery errors. Google Client Secret and SMTP credentials belong only in Supabase settings. A new Hosting deploy is required for these UI changes. Native Google redirects are not configured yet.

## Layout

```text
lib/
  core/providers.dart
  main.dart
  features/
    auth/
      domain/auth_repository.dart
      data/supabase_auth_repository.dart
      presentation/{auth_providers,login_screen}.dart
    profile/
      domain/profile.dart
      data/supabase_profile_repository.dart
      presentation/profile_providers.dart
    learning/
      domain/lesson.dart
      data/learning_repositories.dart
      presentation/{gameplay_controller,lesson_screen}.dart
      presentation/widgets/mechanics.dart
assets/{animations/success.json,maps/slovakia.png}
supabase/{migrations/,seed.sql,tests/}
test/gameplay_test.dart
scripts/bootstrap.sh
docs/{ROADMAP,CURRICULUM,VALIDATION}.md
```

Domain interfaces isolate Supabase transport. Riverpod supplies repositories and authentication state. Profile loading is scoped by current user; a successful server submission invalidates it. The auto-disposed lesson controller owns question index, answers, score, wall-clock deadline and animation trigger. Responses after disposal cannot mutate state. Retry starts a fresh attempt; failed sync is shown as an error instead of fabricated success. RPC grading is transactional and serializes rewards with a profile-row lock.

Mechanics: a CustomPainter right triangle and decimal input; tappable detective tokens with check/cross plus green/red feedback; an aspect-ratio-locked map image with normalized coordinates, a custom pin and server radius validation. The map is an original schematic, not official cartography. Its viewport is longitude 16.8–22.6, latitude 47.6–49.65; Bojnice maps approximately to (0.307, 0.424). The radius is measured in normalized image axes, not kilometres.

`rpg_chat`, `drag_drop`, theory and boss-fight types are reserved in the schema; their gameplay is not implemented in this MVP.
