#!/bin/sh
# Gemeinsame Flutter-/CocoaPods-Umgebung für Xcode Cloud ci_scripts.

FLUTTER_VERSION="${FLUTTER_VERSION:-3.41.5}"
FLUTTER_DIR="${FLUTTER_DIR:-$HOME/flutter}"
FLUTTER_NETWORK_RETRIES="${FLUTTER_NETWORK_RETRIES:-8}"

retry() {
  attempts="$1"
  shift

  n=1
  while [ "$n" -le "$attempts" ]; do
    echo "--- Attempt $n/$attempts: $* ---"
    if "$@"; then
      return 0
    fi

    if [ "$n" -lt "$attempts" ]; then
      wait_seconds=$((n * 15))
      echo "--- Failed, waiting ${wait_seconds}s before retry ---"
      sleep "$wait_seconds"
    fi

    n=$((n + 1))
  done

  echo "--- All $attempts attempts failed for: $* ---"
  return 1
}

wait_for_network() {
  echo "--- Waiting for network (storage.googleapis.com) ---"
  retry "$FLUTTER_NETWORK_RETRIES" curl -fsS \
    --connect-timeout 15 \
    --max-time 45 \
    -o /dev/null \
    "https://storage.googleapis.com/flutter_infra_release/releases/releases_macos.json"
}

dart_sdk_ready() {
  [ -x "$FLUTTER_DIR/bin/cache/dart-sdk/bin/dart" ]
}

bootstrap_flutter() {
  if dart_sdk_ready; then
    echo "--- Flutter/Dart SDK already present ---"
    return 0
  fi

  wait_for_network

  echo "--- Bootstrapping Flutter (Dart SDK download) ---"
  retry "$FLUTTER_NETWORK_RETRIES" "$FLUTTER_DIR/bin/flutter" --version
}

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
    retry "$FLUTTER_NETWORK_RETRIES" git clone \
      https://github.com/flutter/flutter.git \
      -b "$FLUTTER_VERSION" \
      --depth 1 \
      "$FLUTTER_DIR"
  fi

  export PATH="$FLUTTER_DIR/bin:$PATH"
  bootstrap_flutter
}

ensure_cocoapods() {
  if ! command -v pod >/dev/null 2>&1; then
    echo "--- Installing CocoaPods ---"
    brew install cocoapods
  fi
}

run_flutter() {
  retry "$FLUTTER_NETWORK_RETRIES" flutter "$@"
}
