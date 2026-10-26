# Firebase Hosting – Flutter 2.0

The application genuinely builds with Flutter. Both `flutter build web` and `npm run build` produce **build/web**, matching `firebase.json`.

```powershell
cd C:\GitHub\Vedomax
npm run build
# Run only when you intend to update the public site:
npx firebase-tools deploy --only hosting --project vedomax
```

The build launcher uses ignored `.env.supabase.json` if present. Only public/publishable client configuration is compiled in; RLS and server grading protect account progression. Never compile a service-role key.

Guest-only build:

```sh
flutter build web --release --no-web-resources-cdn --dart-define-from-file=config/demo.json
```

Guest mode saves progress on this device and exposes all 336 questions without an account or SMTP. ZIP names in historical release notes are no longer current artifacts.

The connected Supabase database was updated and checked. **Firebase Hosting was not deployed.** The local release directory is ready. After publication, verify real email login, confirmation return and profile sync in the published browser application.
