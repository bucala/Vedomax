#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ ! -f .env.supabase.json ]]; then
  echo 'Chýba .env.supabase.json. Nastav DEMO_MODE=false, SUPABASE_URL a verejný SUPABASE_ANON_KEY.' >&2
  exit 1
fi
exec flutter run --dart-define-from-file=.env.supabase.json "$@"
