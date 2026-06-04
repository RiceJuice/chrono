import 'dart:io';
import 'dart:math' as math;

import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Zielmaße für Termin-Fotos (volle Modalbreite × Modalhöhe, Hochformat).
class EventAttachmentCaptureMetrics {
  const EventAttachmentCaptureMetrics({
    required this.targetWidthPx,
    required this.targetHeightPx,
  });

  final int targetWidthPx;
  final int targetHeightPx;

  double get aspectRatio => targetWidthPx / targetHeightPx;

  static EventAttachmentCaptureMetrics fromContext(BuildContext context) {
    final view = appSheetViewMediaQuery(context);
    final dpr = view.devicePixelRatio;
    return EventAttachmentCaptureMetrics(
      targetWidthPx: EventAttachmentImageNormalizer.targetWidthPxFromContext(
        view.size.width,
        dpr,
      ),
      targetHeightPx: (appSheetHeightBelowSystemUi(context) * dpr).round(),
    );
  }
}

/// Ergebnis der Normalisierung.
class EventAttachmentNormalizedImage {
  const EventAttachmentNormalizedImage({
    required this.file,
    required this.width,
    required this.height,
  });

  final File file;
  final int width;
  final int height;

  double get aspectRatio => width / height;
}

/// EXIF-Orientierung, dann Cover-Zuschnitt auf Modal-Hochformat.
abstract final class EventAttachmentImageNormalizer {
  EventAttachmentImageNormalizer._();

  static const int _jpegQuality = 88;

  static Future<EventAttachmentNormalizedImage?> normalizeForEventModal(
    File source, {
    required EventAttachmentCaptureMetrics metrics,
  }) async {
    final tw = metrics.targetWidthPx;
    final th = metrics.targetHeightPx;
    if (tw <= 0 || th <= 0) return null;

    try {
      final raw = await source.readAsBytes();
      final decoded = img.decodeImage(raw);
      if (decoded == null) return null;

      final oriented = img.bakeOrientation(decoded);
      final cropped = _coverCropCenter(oriented, tw, th);

      final jpg = Uint8List.fromList(
        img.encodeJpg(cropped, quality: _jpegQuality),
      );

      final dir = await getTemporaryDirectory();
      final destPath = p.join(
        dir.path,
        'chrono_photo_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      final dest = File(destPath);
      await dest.writeAsBytes(jpg, flush: true);

      return EventAttachmentNormalizedImage(
        file: dest,
        width: cropped.width,
        height: cropped.height,
      );
    } catch (e, stack) {
      debugPrint('[EventAttach] normalize failed: $e\n$stack');
      return null;
    }
  }

  /// Skaliert so, dass [targetW]×[targetH] vollständig bedeckt ist, dann Mitte crop.
  static img.Image _coverCropCenter(img.Image src, int targetW, int targetH) {
    final scale = math.max(targetW / src.width, targetH / src.height);
    final scaledW = (src.width * scale).round().clamp(1, 16384);
    final scaledH = (src.height * scale).round().clamp(1, 16384);
    final scaled = img.copyResize(
      src,
      width: scaledW,
      height: scaledH,
      interpolation: img.Interpolation.average,
    );
    final x = ((scaled.width - targetW) / 2).round().clamp(0, scaled.width - 1);
    final y = ((scaled.height - targetH) / 2).round().clamp(0, scaled.height - 1);
    final cropW = targetW.clamp(1, scaled.width - x);
    final cropH = targetH.clamp(1, scaled.height - y);
    return img.copyCrop(
      scaled,
      x: x,
      y: y,
      width: cropW,
      height: cropH,
    );
  }

  static int targetWidthPxFromContext(
    double logicalWidth,
    double devicePixelRatio,
  ) {
    return (logicalWidth * devicePixelRatio).round().clamp(1, 8192);
  }

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
