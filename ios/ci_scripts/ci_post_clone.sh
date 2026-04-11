#!/bin/sh

# 1. Verhindern, dass Homebrew versucht, interaktiv zu werden oder Updates zu erzwingen
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1

# 2. Flutter Pfad definieren (Wir installieren es lokal im CI-Verzeichnis, um sudo zu vermeiden)
cd .. # Gehe vom scripts Ordner ins ios Verzeichnis
cd .. # Gehe ins Root Verzeichnis des Projekts

# 3. Flutter via Git klonen (schneller und sicherer als brew in der CI)
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter..."
  git clone https://github.com/flutter/flutter.git -b stable flutter
fi

# 4. Flutter zum Pfad hinzufügen
export PATH="$PWD/flutter/bin:$PATH"

# 5. Flutter Pre-cache (lädt benötigte Artefakte für iOS)
flutter precache --ios

# 6. Abhängigkeiten laden
flutter pub get

# 7. CocoaPods Installation (Xcode Cloud hat diese oft schon, aber sicher ist sicher)
cd ios
pod install

echo "Flutter setup complete. Starting build..."