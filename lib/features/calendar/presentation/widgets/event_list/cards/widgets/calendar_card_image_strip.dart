import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';

/// Bildstreifen rechts in der Listen-Karte — bündig an der Kartenkante,
/// Abstand zum Text wie [_kCalendarCardImageGap].
class CalendarCardImageStrip extends StatelessWidget {
  const CalendarCardImageStrip({
    super.key,
    required this.image,
    this.overlayColor,
    this.minHeight = AppDimensions.eventCardImageHeight,
  });

  final Widget image;
  final Color? overlayColor;
  final double minHeight;

  /// Gleicher Abstand wie zwischen Karussell-Bildern im Event-Modal.
  static const double imageGap = AppSpacing.xs;

  static final SmoothBorderRadius _borderRadius =
      AppSquircle.borderRadius(AppRadius.s);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: imageGap),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: AppDimensions.eventCardImageWidth,
          maxWidth: AppDimensions.eventCardImageWidth,
          minHeight: minHeight,
        ),
        child: ClipSmoothRect(
          radius: _borderRadius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(child: image),
              if (overlayColor != null)
                Positioned.fill(child: ColoredBox(color: overlayColor!)),
            ],
          ),
        ),
      ),
    );
  }
}
