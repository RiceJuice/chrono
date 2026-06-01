import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:flutter/material.dart';

/// Bildstreifen rechts in der Listen-Karte: volle Kartenhöhe, rechte Ecken
/// passend zum Karten-Radius.
class CalendarCardImageStrip extends StatelessWidget {
  const CalendarCardImageStrip({
    super.key,
    required this.image,
    this.overlayColor,
  });

  final Widget image;
  final Color? overlayColor;

  static final BorderRadius _borderRadius = BorderRadius.only(
    topRight: Radius.circular(AppRadius.s),
    bottomRight: Radius.circular(AppRadius.s),
  );

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: AppDimensions.eventCardImageWidth,
        maxWidth: AppDimensions.eventCardImageWidth,
        minHeight: AppDimensions.eventCardImageHeight,
      ),
      child: ClipRRect(
        borderRadius: _borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: image),
            if (overlayColor != null)
              Positioned.fill(child: ColoredBox(color: overlayColor!)),
          ],
        ),
      ),
    );
  }
}
