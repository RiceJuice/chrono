#!/bin/sh

# Xcode Cloud: Flutter-SDK und Dart-Abhängigkeiten nach dem Clone.
# Pod install und Tests laufen in ci_pre_xcodebuild.sh (eigenes Timeout-Budget).

set -e

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "$SCRIPT_DIR/flutter_env.sh"

setup_flutter

echo "--- Fetching dependencies ---"
flutter precache --ios
flutter pub get

echo "--- Generating iOS configuration ---"
flutter build ios --config-only --no-codesign

ensure_cocoapods

echo "--- ci_post_clone complete ---"
