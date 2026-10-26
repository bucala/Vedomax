#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
flutter --version
# Generate platform shells in isolation; never overwrite hand-written app files.
if [[ ! -d android || ! -d ios ]]; then
  scaffold_dir="$(mktemp -d /tmp/vedomax-platforms.XXXXXX)"
  trap 'rm -rf "$scaffold_dir"' EXIT
  flutter create --no-pub --platforms=android,ios --org sk.vedomax --project-name vedomax "$scaffold_dir"
  for platform in android ios; do
    if [[ ! -d "$platform" ]]; then cp -R "$scaffold_dir/$platform" "$platform"; fi
  done
fi
if [[ -f pubspec.lock ]]; then flutter pub get --enforce-lockfile; else flutter pub get; fi
flutter analyze
flutter test
flutter build web --release --dart-define=DEMO_MODE=true
