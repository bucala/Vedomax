#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
flutter pub get --enforce-lockfile
# Deliberately use only the public demo config, not .env.supabase.json.
flutter build web --release --no-pub --dart-define-from-file=config/demo.json "$@"
