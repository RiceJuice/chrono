import 'package:chronoapp/core/widgets/calendar_progressive_blur.dart';
import 'package:flutter/material.dart';
import 'package:inspire_blur/inspire_blur.dart';

/// Gleiche Werte wie der Event-Sheet-Top-Blur (Ablaufplan), nur leichter.
const double kSettingsScrollTopBlurOverlayHeight = 76;
const double kSettingsScrollTopBlurMaxSigma = 3;
const double kSettingsScrollTopBlurTintAlpha = 0.05;
const Curve kSettingsScrollTopBlurTintCurve = Curves.easeInSine;

/// Progressiver Blur-Streifen oben — blendet mit dem AppBar-Titel ein.
class SettingsScrollTopBlurOverlay extends StatelessWidget {
  const SettingsScrollTopBlurOverlay({
    super.key,
    required this.strength,
    required this.surfaceColor,
  });

  /// 0…1, gesteuert über Scroll-Offset in [SettingsPage].
  final double strength;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    if (strength <= 0) {
      return const SizedBox.shrink();
    }

    final effectiveStrength = strength.clamp(0.0, 1.0);
    final maxSigma = kSettingsScrollTopBlurMaxSigma * effectiveStrength;
    final tintAlpha = kSettingsScrollTopBlurTintAlpha * effectiveStrength;

    return IgnorePointer(
      child: SizedBox(
        height: kSettingsScrollTopBlurOverlayHeight,
        width: double.infinity,
        child: CalendarProgressiveBackdropBlur(
          config: calendarEventSheetTopBlurConfig(sigma: maxSigma),
          fadeCurve: kSettingsScrollTopBlurTintCurve,
          useRepaintBoundary: false,
          child: Inspire.tint.topToBottom(
            color: surfaceColor,
            opacity: tintAlpha,
            extent: 1.0,
            curve: kSettingsScrollTopBlurTintCurve,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}
