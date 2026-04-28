// ignore_for_file: avoid_print

import 'dart:io';

import 'package:image/image.dart' as img;

/// Erzeugt einfarbiges 1024×1024 PNG für flutter_launcher_icons, bis echte Assets aus dem SVG exportiert sind.
/// Aufruf: dart run tool/create_placeholder_app_icons.dart
void main() {
  Directory('assets/icon').createSync(recursive: true);

  // Fester App-Icon-Hintergrund (#111827)
  const backgroundR = 0x11;
  const backgroundG = 0x18;
  const backgroundB = 0x27;

  // Platzhalter-Foreground (spaeter durch echtes transparentes Foreground-Asset ersetzen)
  const foregroundR = 0xCB;
  const foregroundG = 0xBB;
  const foregroundB = 0xA0;

  _writeSolid(
    'assets/icon/app_icon.png',
    backgroundR,
    backgroundG,
    backgroundB,
  );
  _writeSolid(
    'assets/icon/app_icon_foreground.png',
    foregroundR,
    foregroundG,
    foregroundB,
  );
  print(
    'Written assets/icon/app_icon.png and app_icon_foreground.png (1024×1024).',
  );
}

void _writeSolid(String path, int r, int g, int b) {
  final image = img.Image(width: 1024, height: 1024);
  img.fill(image, color: img.ColorRgb8(r, g, b));
  File(path).writeAsBytesSync(img.encodePng(image));
}
