# App-Icon-Quellen

`flutter_launcher_icons` benötigt **PNG**, kein SVG.

1. Aus dem Logo-SVG exportieren (z. B. Inkscape/Figma), jeweils **1024×1024 px**:
   - **`app_icon.png`** – fertiges Launcher-Icon (Hintergrund + Logo).
   - **`app_icon_foreground.png`** – Vordergrund für Android Adaptive Icons: Logo zentriert, ~25 % Rand zum Rand, Hintergrund **transparent**, die Flächenfarbe kommt aus `adaptive_icon_background` in `pubspec.yaml`.

2. Dateien hier ablegen (gleiche Namen wie oben).

3. Im Projektroot ausführen:
   ```bash
   dart run flutter_launcher_icons
   ```

Platzhalter-PNGs können mit `dart run tool/create_placeholder_app_icons.dart` erzeugt werden.
