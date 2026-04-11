#!/bin/sh

# 1. Flutter installieren (Homebrew ist auf Xcode Cloud vorinstalliert)
brew install --cask flutter

# 2. Flutter in den Pfad aufnehmen
export PATH="$PATH:/usr/local/bin"

# 3. Flutter Abhängigkeiten laden
flutter pub get

# 4. Flutter iOS Build vorbereiten (generiert die notwendigen nativen Dateien)
# --release sorgt dafür, dass alles für den Store optimiert wird
flutter build ios --release --no-codesign