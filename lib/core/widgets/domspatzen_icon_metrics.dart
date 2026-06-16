/// Gemeinsame SVG-Maße für das Domspatzen-Icon (Tab-Bar, Suchleiste).
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
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

  static Future<Uint8List?> renderTabIconPngBytes({
    required Color color,
    required double glyphSize,
  }) async {
    final assetSize = assetSizeForGlyph(glyphSize);
    final loader = SvgAssetLoader(
      assetPath,
      colorMapper: _DomspatzenTintColorMapper(color),
    );
    final pictureInfo = await vg.loadPicture(loader, null);

    final pixelRatio =
        ui.PlatformDispatcher.instance.views.firstOrNull?.devicePixelRatio ?? 1.0;
    final pixelSize = (assetSize * pixelRatio).ceil();
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

    final image = await recorder.endRecording().toImage(pixelSize, pixelSize);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return byteData?.buffer.asUint8List();
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
