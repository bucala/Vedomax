# Vedomax

**Vedomax - Vedomosti na Maximum pre všetky deti**

Flutter 3.47 / Dart 3.13 application for grades 8 and 9 of Slovak primary schools. The React prototype has been replaced with real Flutter; `npm` commands are convenience launchers for the Flutter SDK.

## Included

- Original generated V mascot/logo, responsive main menu, subject cards and a two-week learning plan.
- The main-menu mascot now animates from the supplied textured OBJ model, with idle/celebration clips and reduced-motion support. See [mascot source and exports](../assets/mascot/README.md).
- **336 authored questions:** 14 days × 3 areas × 4 questions × 2 grades. Mathematics, Slovak language/literature and geography.
- Numeric answers including negatives and decimal commas; multiple-choice cards; keyboard/touch maps with geographical coordinates.
- Answer → correct solution and explanation → explicit “Zobraziť body” → animated score → next question. Map feedback reveals both markers and distance before points.
- Distance points: 100 within 10 km in Slovakia / 70 km abroad; linear decrease to zero at 250 / 2,200 km. Thresholds are shown before answering. Four answers give up to 400 points; the lesson percentage contributes at most 100 XP.
- Best-score XP, streaks using Europe/Bratislava dates, and guest progress saved on this device. Account progress is separate and never trusts guest XP.
- Settings: grade, system/light/dark theme, reduced motion, haptics, daily goal, nickname and optional leaderboard participation.
- Real Supabase email authentication, server grading, answer receipts, profiles and opt-in leaderboard. No password-based local account fallback.

## Run

Install the [Flutter SDK](https://docs.flutter.dev/install/manual) and add its `bin` to PATH, or set `FLUTTER_ROOT`. This development machine also has an SDK at `%USERPROFILE%\.codex\toolchains\flutter`.

```sh
flutter pub get
flutter run -d web-server --web-port=3000
```

Or use `npm run dev`; the launcher detects the SDK and reads the ignored `.env.supabase.json` if present. Local URL: **http://127.0.0.1:3000**. Node dependencies are only needed for the optional database test engine.

## Accounts

Copy [.env.example](../.env.example) to `.env.supabase.json` and supply the Supabase URL and publishable key. Never use a service-role key.

```sh
flutter run -d web-server --web-port=3000 --dart-define-from-file=.env.supabase.json
```

The connected Vedomax database has the daily schema and 84 daily lessons installed. For a **new** database, apply `supabase/migrations/202610260001_core.sql`, `supabase/seed.sql`, then `supabase/migrations/20261026201821_daily_learning_v2.sql`, in that order. The seed supplies the subjects required by the second migration. Do not reapply these files to the existing hosted project.

Email confirmation needs Auth URL and SMTP configuration; see [AUTH_SETUP.md](AUTH_SETUP.md). Guest practice works without Supabase.

Old browser mock accounts stored plaintext passwords and could share IDs. They are retired; Flutter web removes those obsolete credential keys on launch. Existing Supabase accounts and progression remain intact. Mock-account results are not silently assigned to real accounts.

## Validate and build

```sh
npm ci
npm run lint
npm test
npm run test:db
npm run build
```

Direct equivalents: `flutter analyze`, `flutter test`, `flutter build web --release --no-web-resources-cdn`. The npm build also supplies account configuration if present. A guest build uses `--dart-define-from-file=config/demo.json`.

Output is **build/web**, matching `firebase.json`. CanvasKit and fonts are bundled locally. This is a web build, not an APK/IPA. Android/iOS shells can be generated with `scripts/bootstrap.sh`; native compilation requires the corresponding toolchains.

`python scripts/package_web.py` creates `output/vedomax-web-2.0.0.zip`, including the compiled release and Firebase hosting configuration. It checks ZIP integrity and excludes environment files.

Render snapshots are in [test/goldens](../test/goldens). See [VALIDATION.md](VALIDATION.md) for verification boundaries and [CURRICULUM.md](CURRICULUM.md) for sources and the fourteen-day topic table.

## Content and artwork

`assets/content/fortnight.json` is the shared offline and server-content source. `scripts/create_curriculum.py` reproduces it using authored questions and the committed GeoNames snapshot. Future published changes require a **new** data migration; never regenerate an applied migration in place.

The V emblem is [assets/brand/vedomax-v.png](../assets/brand/vedomax-v.png). Its ImageGen prompt is in [assets/brand/README.md](../assets/brand/README.md). Natural Earth map data is public domain; GeoNames coordinates are CC BY 4.0. Roboto includes its licence.
