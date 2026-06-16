#!/bin/sh

# Xcode Cloud: CocoaPods und Unit-Tests vor xcodebuild.
# Getrennt von ci_post_clone, damit pod install ein eigenes Timeout-Budget hat.

set -e

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "$SCRIPT_DIR/flutter_env.sh"

setup_flutter
ensure_cocoapods

echo "--- Running Unit Tests ---"
run_flutter test

echo "--- Preparing iOS build ---"
cd ios
pod install --deployment

echo "--- ci_pre_xcodebuild complete ---"
