/// Gemeinsame SVG-Maße für das Domspatzen-Icon (Tab-Bar, Suchleiste).
library;

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

abstract final class DomspatzenIconMetrics {
  static const assetPath = 'assets/domspatzen.svg';

  static const viewBoxWidth = 1025.0;
  static const viewBoxHeight = 1024.0;
  static const visualTopY = 139.0;
  static const visualBottomY = 889.5;

  static const visibleHeightFraction =
      (visualBottomY - visualTopY) / viewBoxHeight;

  static double assetSizeForGlyph(double glyphSize) =>
      glyphSize / visibleHeightFraction;

  /// Rasterisiert das SVG für die native iOS-Tab-Bar (PNG mit Theme-Farbe).
  ///
  /// [context] sollte gesetzt sein, damit Asset-Loading und devicePixelRatio
  /// auf echten Geräten zuverlässig funktionieren (nicht nur im Simulator).
  /// Kurz warten, bis die GPU nach App-Start bereit ist (wichtig auf echten Geräten).
  static Future<void> waitForGpuReady(int attempt) async {
    final binding = WidgetsBinding.instance;
    if (binding.framesEnabled) {
      await binding.endOfFrame;
    }
    if (attempt > 0) {
      await Future<void>.delayed(Duration(milliseconds: 16 * attempt));
    }
  }

  static Future<Uint8List?> renderTabIconPngBytes({
    BuildContext? context,
    double? devicePixelRatio,
    required Color color,
    required double glyphSize,
  }) async {
    try {
      final assetSize = assetSizeForGlyph(glyphSize);
      final pixelRatio =
          devicePixelRatio ?? _resolvePixelRatio(context);
      final svgString = await rootBundle.loadString(assetPath);
      final loader = SvgStringLoader(
        svgString,
        colorMapper: _DomspatzenTintColorMapper(color),
      );
      final pictureInfo = await vg.loadPicture(loader, null);
      await waitForGpuReady(0);

      final pixelSize = (assetSize * pixelRatio).ceil().clamp(1, 512);
      final scale = assetSize / viewBoxHeight;
      final drawnWidth = viewBoxWidth * scale;
      final drawnHeight = viewBoxHeight * scale;
      final offsetX = (assetSize - drawnWidth) / 2;
      final offsetY = (assetSize - drawnHeight) / 2;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.scale(pixelRatio);
      canvas.translate(offsetX, offsetY);
      canvas.scale(scale);
      canvas.drawPicture(pictureInfo.picture);
      pictureInfo.picture.dispose();

      final image = await recorder.endRecording().toImage(
        pixelSize,
        pixelSize,
      );
      final rgba = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
      if (rgba == null || !_hasVisibleInk(rgba, pixelSize)) {
        image.dispose();
        return null;
      }

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return byteData?.buffer.asUint8List();
    } catch (error, stackTrace) {
      debugPrint('DomspatzenIconMetrics.renderTabIconPngBytes failed: $error');
      debugPrint('$stackTrace');
      return null;
    }
  }

  static bool _hasVisibleInk(ByteData rgba, int pixelSize) {
    final bytes = rgba.buffer.asUint8List();
    for (var y = 0; y < pixelSize; y++) {
      final rowOffset = y * pixelSize * 4;
      for (var x = 0; x < pixelSize; x++) {
        if (bytes[rowOffset + x * 4 + 3] != 0) {
          return true;
        }
      }
    }
    return false;
  }

  static double _resolvePixelRatio(BuildContext? context) {
    if (context != null) {
      return MediaQuery.devicePixelRatioOf(context);
    }
    final views = ui.PlatformDispatcher.instance.views;
    return views.isNotEmpty ? views.first.devicePixelRatio : 3.0;
  }
}

final class _DomspatzenTintColorMapper extends ColorMapper {
  const _DomspatzenTintColorMapper(this.color);

  final Color color;

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    return this.color;
  }
}
