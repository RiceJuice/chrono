/// Gemeinsame SVG-Maße für das Domspatzen-Icon (Tab-Bar, Suchleiste).
library;

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
}
