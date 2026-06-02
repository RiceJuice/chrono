import 'package:flutter/material.dart';
import 'package:figma_squircle/figma_squircle.dart';

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 20;
}

class AppRadius {
  AppRadius._();

  static const double s = 10;
  static const double m = 12;
  static const double l = 14;
  static const double xl = 16;

  /// Bottom-Sheets / Modals (iOS-ähnlich, deutlich runder als [xl]).
  static const double sheet = 28;

  static const double pill = 100;
}

class AppSquircle {
  AppSquircle._();

  /// 0.6 ist die gängige Figma/iOS-Näherung für „squircle“-artige Ecken.
  static const double cornerSmoothing = 0.6;

  static SmoothBorderRadius borderRadius(double r) => SmoothBorderRadius(
        cornerRadius: r,
        cornerSmoothing: cornerSmoothing,
      );

  static SmoothBorderRadius topSheet(double r) => SmoothBorderRadius.only(
        topLeft: SmoothRadius(
          cornerRadius: r,
          cornerSmoothing: cornerSmoothing,
        ),
        topRight: SmoothRadius(
          cornerRadius: r,
          cornerSmoothing: cornerSmoothing,
        ),
      );

  static SmoothRectangleBorder shape(double r, {BorderSide side = BorderSide.none}) {
    return SmoothRectangleBorder(
      side: side,
      borderRadius: borderRadius(r),
    );
  }
}

class AppInsets {
  AppInsets._();

  static const EdgeInsets inputContent = EdgeInsets.symmetric(
    horizontal: AppSpacing.m,
    vertical: AppSpacing.m,
  );
  static const EdgeInsets buttonContent = EdgeInsets.symmetric(
    horizontal: AppSpacing.l,
    vertical: AppSpacing.m,
  );
  static const EdgeInsets buttonContentWide = EdgeInsets.symmetric(
    horizontal: 26,
    vertical: AppSpacing.s,
  );
  static const EdgeInsets cardPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: AppSpacing.s,
  );
  static const EdgeInsets eventCardContent = EdgeInsets.only(
    left: 14,
    right: 14,
    top: AppSpacing.s,
    bottom: AppSpacing.s,
  );

  /// Wie [eventCardContent], für die kompakte Wochen-Raster-Karte.
  static const EdgeInsets eventCardContentCompact = EdgeInsets.only(
    left: AppSpacing.s,
    right: AppSpacing.s,
    top: 4,
    bottom: 4,
  );
}

class AppOpacity {
  AppOpacity._();

  static const double subtle = 0.08;
  static const double low = 0.10;
  static const double muted = 0.20;
  static const double disabled = 0.60;
  static const double selectedFill = 0.44;
  static const double selectedStroke = 0.95;
  static const double secondaryContent = 0.54;
}

class AppDimensions {
  AppDimensions._();

  static const double eventCardImageWidth = 120;
  static const double eventCardImageHeight = 96;
  static const double mealCardImageMaxHeight = 200;
  static const double eventCardDescriptionSpacing = 12;
}
