#!/bin/sh

# 1. Fehlerbehandlung: Stop bei jedem Fehler
set -e

# 2. Homebrew-Interaktionen unterdrücken
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1

# 3. Ins Root-Verzeichnis wechseln
cd ../..

# 4. Flutter Installation (Feste Version für Stabilität)
# TIPP: Schau lokal mit 'flutter --version' nach und trage sie hier ein.
FLUTTER_VERSION="3.41.5" 

if [ ! -d "flutter" ]; then
  echo "--- Cloning Flutter $FLUTTER_VERSION ---"
  git clone https://github.com/flutter/flutter.git -b $FLUTTER_VERSION --depth 1 flutter
fi

# 5. Pfad setzen
export PATH="$PWD/flutter/bin:$PATH"

# 6. Abhängigkeiten laden
echo "--- Fetching dependencies ---"
flutter precache --ios
flutter pub get

# 7. UNIT TESTS HINZUFÜGEN
# Wenn die Tests fehlschlagen, bricht der Build hier ab (wegen set -e)
echo "--- Running Unit Tests ---"
flutter test

# 8. iOS / CocoaPods Fixes
echo "--- Preparing iOS build ---"
cd ios

# Radikaler Cleanup um die XCFileList Fehler zu vermeiden
rm -rf Pods
rm -rf DevPods
rm -f Podfile.lock

# Pods sauber neu installieren
pod install

cd ..

echo "--- Setup & Tests successful. Starting Xcode Cloud build ---"