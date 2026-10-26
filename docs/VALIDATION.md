# Validation – Flutter 2.0, 2026-10-26

## OBJ mascot animation update

- Imported the supplied Meshy OBJ/MTL/PNG locally in Blender 5.1.2, preserving its texture and original Downloads files. Added a deformation skeleton, geodesic arm weights and two looping animation actions.
- Saved a packed editable `.blend` and a GLB containing a skin plus `Idle_Wave` and `Celebrate` animation channels.
- Rendered/inspected transparent RGBA sequences and encoded 60-frame idle / 36-frame celebration clips at 20 fps, 384 × 384. Runtime WebP files total approximately 1.36 MB; the 32 MB GLB is not downloaded by the application.
- Added codec tests for frame counts, frame duration, alpha and changing pixels, plus widget checks for tap-to-celebrate, return-to-idle, reduced motion and inactive-page pausing. The complete Flutter suite now contains 13 passing tests.
- Updated and visually reviewed menu render snapshots using the supplied 3D character, then rebuilt the web release. Runtime assets and the deployment ZIP include both animation clips.

## Executed

- Installed genuine Flutter 3.47.8 / Dart 3.13.7. Removed the shell file that had impersonated Flutter while running Vite.
- Flutter static analysis and release web compilation; npm commands call the same SDK. The web build passes the Wasm compatibility dry run and emits `build/web`, matching Firebase configuration.
- Flutter unit/widget/render tests: bank completeness (336 unique question IDs, 84 lessons), correct/incorrect grading, strict numeric parsing, map distance/partial credit, bounds of every map target, persistence, XP replay caps, Bratislava midnight/streaks, desktop/mobile rendering, settings, four-question completion and solution-before-score ordering.
- Mock-HTTP account integration test: server profile and progression reads, authoritative RPC rewards, nickname and leaderboard updates, and guest/account separation on sign-out. It exercises the real Supabase Dart client against an isolated transport fixture, not a real email login.
- Rendered and inspected desktop/mobile menu snapshots with bundled Roboto, icon fonts and the actual generated V mascot. Additional feedback/settings snapshots are covered by the widget suite.
- In-memory PostgreSQL with PGlite: original SQL security suite and all 336 new server-graded answers; question sequence, immutable reveal receipts, idempotent completion, XP ceilings, partial map scores, private-table denial, direct-XP-write denial, user isolation and anonymous denial.
- Applied `daily_learning_v2` to connected Supabase project `uifthknpirbcexiqeqmx`. The update adds 84 daily lessons / 336 questions without deleting existing content or account data.
- Hosted `supabase/tests/daily_security.sql` passed. Its temporary auth identities, attempts and scores were rolled back.
- Prepared local ignored configuration with the existing publishable key. No service-role key is embedded. Local web server started at `http://127.0.0.1:3000`.

## Security review

The local credential store, truncated email-derived IDs, duplicate-registration password overwrite, fake leaderboard and local profile repository are removed. Authenticated profile/leaderboard operations use the server. Guest data is isolated and never used for account awards. Leaderboard visibility is opt-in. New server functions validate `auth.uid()`, use an empty search path, serialize on the owner's profile, and expose only authenticated RPC entry points. Private attempt/answer tables intentionally have RLS without user policies: users access them through validated functions only. Trigger-only `create_profile` execution was revoked from authenticated clients.

Supabase advisors still identify intentional authenticated SECURITY DEFINER RPCs. These are required to grade private answer keys and update protected XP. The project's pre-existing leaked-password-protection setting is disabled; this account-level setting was not changed by the application migration.

## Boundaries

- Firebase Hosting has not been published. No APK/IPA has been built.
- The browser connector has no attached browser. Native Chrome windows are minimized and the available CUA binding cannot capture them in that state; no browser gameplay result is claimed. Flutter widget interactions and real render snapshots were verified instead.
- Real-user login/registration, confirmation delivery and SMTP configuration have not been exercised. No test email was sent.
- Content follows the cited official topic/grade standards, with original practice questions. It is not ministerially certified or teacher-approved; a school's ŠkVP may schedule content differently.
- The build may emit Flutter's Cupertino icon-family warning even though this UI uses Material icons. It does not prevent compilation.

## Repeat

```sh
npm ci
npm run lint
npm test
npm run test:db
npm run build
```

`npm run test:db` runs an isolated local database; it does not connect to Supabase. Render golden files were created on Windows with the bundled font versions; platform renderer differences can require a reviewed golden refresh.
