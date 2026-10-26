# Firebase Hosting

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

Run in a terminal (Cloud Shell is suitable), never in Supabase SQL Editor. Replace `YOUR_FIREBASE_PROJECT_ID` with the verified project ID:

```sh
npx --yes firebase-tools@14 login --no-localhost
npx --yes firebase-tools@14 deploy --only hosting --project YOUR_FIREBASE_PROJECT_ID
```

Complete Google authorization only in Google's browser flow. The CLI prints the actual Hosting URL after successful deployment; do not assume a project ID or invent a publication URL. Deployment publishes the web application, not a native Android/iOS package.

After publication, in Supabase → Authentication → URL Configuration, set the Site URL to the actual Hosting URL and allow only the specific redirect paths needed for your authentication flow. Test registration, email confirmation, login, lesson completion and profile XP persistence on the published site. Do not declare hosted mode working from a static HTML response alone.
