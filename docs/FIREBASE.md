# Firebase Hosting

Current release: **email/password only**. Use `/workspace/scratch/vedomax-email-only.zip`; the older Google-login and auth-return archives below are historical. See `docs/AUTH_SETUP.md` for server-side Google disablement and SMTP setup.

Firebase serves the compiled Flutter web app; Supabase continues to provide authentication and the database. Firestore, Firebase Auth and a Firebase client SDK are not required for this architecture.

The repository's `firebase.json` deploys only `build/web`, never the repository root or the local Supabase configuration file. SPA rewrites support browser navigation, and no-cache headers require clients to revalidate after releases.

## Deployment prerequisites

- The actual Firebase **Project ID**, found in Firebase Console → Project settings → General. Do not substitute the project display name or the Supabase project reference.
- Hosting enabled in that Firebase project.
- A user authenticated to Firebase CLI with permission to deploy Hosting. A public Supabase key is not a Firebase deployment credential. Never paste account passwords, login codes or service-account keys into chat.

Firebase Console alone does not run terminal commands or upload an arbitrary Flutter source repository. A browser-only workflow can use **Google Cloud Shell** (https://shell.cloud.google.com/) for its terminal, authenticated to the intended Google account. This is separate from the Supabase SQL Editor.

## Build in the prepared development workspace

```sh
cd /workspace/Vedomax
export PATH="/workspace/toolchains/flutter/bin:$PATH"
export PUB_CACHE=/workspace/toolchains/pub-cache
export XDG_CONFIG_HOME=/workspace/toolchains/config
export ANALYZER_STATE_LOCATION_OVERRIDE=/workspace/toolchains/analyzer-state
flutter pub get --enforce-lockfile
flutter analyze --no-pub
flutter test --no-pub
flutter build web --release --dart-define-from-file=.env.supabase.json
```

For browser-only deployment, transfer the prepared `build/web` directory and `firebase.json` to Cloud Shell, preserving their relative paths. This avoids installing Flutter again in Cloud Shell. Do not upload `.env.supabase.json` or private credentials. Compiled web assets necessarily contain the public Supabase URL and publishable key; access is protected by Supabase RLS and user authentication.

## Deploy from the directory containing firebase.json

Run in a terminal (Cloud Shell is suitable), never in Supabase SQL Editor. The selected project ID is `vedomax`:

```sh
npx --yes firebase-tools@14 login --no-localhost
npx --yes firebase-tools@14 deploy --only hosting --project vedomax
```

Complete Google authorization only in Google's browser flow. The CLI prints the actual Hosting URL after successful deployment; do not assume a project ID or invent a publication URL. Deployment publishes the web application, not a native Android/iOS package.

After publication, in Supabase → Authentication → URL Configuration, set the Site URL to the actual Hosting URL and allow only the specific redirect paths needed for your authentication flow. Test registration, email confirmation, login, lesson completion and profile XP persistence on the published site. Do not declare hosted mode working from a static HTML response alone.

## Prepared browser-only bundle

The current cloud workspace has `/workspace/scratch/vedomax-firebase.zip`, built with the supplied public Supabase configuration. This artifact is not committed to Git. Download it, upload it through the Cloud Shell menu (Upload), and run:

```sh
unzip vedomax-firebase.zip
cd vedomax-hosting
npx --yes firebase-tools@14 login --no-localhost
npx --yes firebase-tools@14 deploy --only hosting --project vedomax
```

The ZIP contains `firebase.json`, `.firebaserc` and `build/web` under `vedomax-hosting/`. It excludes local environment configuration and source secrets. Use an empty extraction directory for a fresh release. The user must complete Google authentication and have Hosting deployment access to this project. The selected ID has not yet been validated through an authenticated Firebase API operation. This archive was created before native Android/iOS packaging and is for web Hosting only.

## Updated Google-login release on Windows PowerShell

Use the new `/workspace/scratch/vedomax-google-login.zip` artifact; the original ZIP predates Google login. Download it into `C:\GitHub\TEST`, then run in **PowerShell**, not Supabase SQL Editor:

```powershell
cd C:\GitHub\TEST
Expand-Archive -Path .\vedomax-google-login.zip -DestinationPath .\google-login-release
cd .\google-login-release\vedomax-hosting
npx --yes firebase-tools@14 deploy --only hosting --project vedomax
```

Google's OAuth client/provider configuration is described in `docs/AUTH_SETUP.md`; a new button alone does not enable the provider. Complete an actual sign-in after deploying. The project owner already demonstrated Firebase deployment access from their Windows Firebase CLI; no new login is normally required there.

## Current email-only release — Windows PowerShell

Download `/workspace/scratch/vedomax-email-only.zip` to `C:\GitHub\TEST`, then run:

```powershell
cd C:\GitHub\TEST
Expand-Archive -Path .\vedomax-email-only.zip -DestinationPath .\email-only-release
cd .\email-only-release\vedomax-hosting
npx --yes firebase-tools@14 deploy --only hosting --project vedomax
```

Use a fresh extraction directory. This publishes the new frontend; it does not modify Supabase provider settings or configure SMTP.
