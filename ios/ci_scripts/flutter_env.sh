#!/bin/sh
# Gemeinsame Flutter-/CocoaPods-Umgebung für Xcode Cloud ci_scripts.

FLUTTER_VERSION="${FLUTTER_VERSION:-3.41.5}"
FLUTTER_DIR="${FLUTTER_DIR:-$HOME/flutter}"

setup_flutter() {
  export HOMEBREW_NO_AUTO_UPDATE=1
  export HOMEBREW_NO_INSTALL_CLEANUP=1
  export COCOAPODS_DISABLE_STATS=true

  if [ -n "${CI_PRIMARY_REPOSITORY_PATH:-}" ]; then
    cd "$CI_PRIMARY_REPOSITORY_PATH"
  else
    # Lokaler Fallback: ios/ci_scripts → Repo-Root
    cd "$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"
  fi

  if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
    echo "--- Cloning Flutter $FLUTTER_VERSION ---"
    git clone https://github.com/flutter/flutter.git -b "$FLUTTER_VERSION" --depth 1 "$FLUTTER_DIR"
  fi

  export PATH="$FLUTTER_DIR/bin:$PATH"
}

ensure_cocoapods() {
  if ! command -v pod >/dev/null 2>&1; then
    echo "--- Installing CocoaPods ---"
    brew install cocoapods
  fi
}
