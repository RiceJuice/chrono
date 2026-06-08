import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Hilfsfunktionen für Termin-Fotos (z. B. Titel-Kontrast über dem Bild).
abstract final class EventAttachmentImageNormalizer {
  EventAttachmentImageNormalizer._();

  /// Titel-Farbe über Bild: heller oberer Bereich → Schwarz, sonst Weiß.
  static Future<Color> titleColorForImageHeader(File imageFile) async {
    try {
      final raw = await imageFile.readAsBytes();
      final decoded = img.decodeImage(raw);
      if (decoded == null) return Colors.white;

      final oriented = img.bakeOrientation(decoded);
      final sampleRows = (oriented.height * 0.18).round().clamp(1, oriented.height);
      var luminanceSum = 0.0;
      var count = 0;

      for (var y = 0; y < sampleRows; y++) {
        for (var x = 0; x < oriented.width; x++) {
          final p = oriented.getPixel(x, y);
          luminanceSum += img.getLuminance(p);
          count++;
        }
      }

      if (count == 0) return Colors.white;
      final avg = luminanceSum / count;
      return avg > 0.52 ? Colors.black : Colors.white;
    } catch (_) {
      return Colors.white;
    }
  }
}
