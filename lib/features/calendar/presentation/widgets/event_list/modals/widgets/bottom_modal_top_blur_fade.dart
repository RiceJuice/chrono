import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:gradient_blur/gradient_blur.dart';

/// Feste Höhe des Blur-Streifens ganz oben im Event-Sheet.
const double kBottomModalTopBlurOverlayHeight = 112;

/// Maximale Blur-Stärke (σ).
const double kBottomModalTopBlurMaxSigma = 4;

/// Deckkraft der Tönungsfarbe oben (0…1).
const double kBottomModalTopBlurTintAlpha = 0.5;

const int kCalendarGradientBlurSlices = 14;
const Curve kCalendarGradientBlurCurve = Curves.easeOutCubic;

/// Scroll-Distanz (px), bis der Event-Top-Blur voll eingeblendet ist.
const double kBottomModalTopBlurFadeScrollDistance = 36;

/// Min. σ für Nachbar-Karten in der Lesson-Vorschau (Anteil von [kBottomModalTopBlurMaxSigma]).
const double kModalPreviewNeighborBlurSigmaMinFactor = 0.22;

/// Tönung Nachbar-Karten — weniger Farbe als zuvor (0.045…0.15).
const double kModalPreviewNeighborGlassTintMin = 0.012;
const double kModalPreviewNeighborGlassTintMax = 0.04;

LinearGradient calendarGradientBlurTintGradient({
  required Color surfaceColor,
  required double tintAlpha,
}) {
  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      surfaceColor.withValues(alpha: tintAlpha),
      surfaceColor.withValues(alpha: 0),
    ],
  );
}

/// Gradient-Blur-Overlay — blurrt den Inhalt darunter (Backdrop-Stapel wie im Event-Sheet).
class CalendarGradientBlurOverlay extends StatelessWidget {
  const CalendarGradientBlurOverlay({
    super.key,
    required this.maxBlur,
    required this.surfaceColor,
    required this.tintAlpha,
    required this.borderRadius,
    required this.child,
  });

  final double maxBlur;
  final Color surfaceColor;
  final double tintAlpha;
  final SmoothBorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (maxBlur <= 0) {
      return child;
    }

    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: ClipSmoothRect(
              radius: borderRadius,
              child: GradientBlur(
                maxBlur: maxBlur,
                minBlur: 0,
                slices: kCalendarGradientBlurSlices,
                curve: kCalendarGradientBlurCurve,
                gradient: calendarGradientBlurTintGradient(
                  surfaceColor: surfaceColor,
                  tintAlpha: tintAlpha,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Stärke 0…1 für den Event-Top-Blur (Vollbild + gescrollt).
double bottomModalTopBlurStrength({
  required bool isFullyExpanded,
  required double contentScrollOffset,
}) {
  if (!isFullyExpanded || contentScrollOffset <= 0) {
    return 0;
  }
  return (contentScrollOffset / kBottomModalTopBlurFadeScrollDistance)
      .clamp(0.0, 1.0);
}

/// Fester Blur-Streifen oben im Event-Sheet.
class BottomModalTopBlurOverlay extends StatelessWidget {
  const BottomModalTopBlurOverlay({
    super.key,
    required this.strength,
    required this.surfaceColor,
  });

  final double strength;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    if (strength <= 0) {
      return const SizedBox.shrink();
    }

    final effectiveStrength = strength.clamp(0.0, 1.0);
    final maxBlur = kBottomModalTopBlurMaxSigma * effectiveStrength;
    final tintAlpha = kBottomModalTopBlurTintAlpha * effectiveStrength;

    return IgnorePointer(
      child: ClipSmoothRect(
        radius: AppSquircle.topSheet(AppRadius.sheet),
        child: SizedBox(
          height: kBottomModalTopBlurOverlayHeight,
          width: double.infinity,
          child: GradientBlur(
            maxBlur: maxBlur,
            minBlur: 0,
            slices: kCalendarGradientBlurSlices,
            curve: kCalendarGradientBlurCurve,
            gradient: calendarGradientBlurTintGradient(
              surfaceColor: surfaceColor,
              tintAlpha: tintAlpha,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

/// Scroll-gesteuerter Top-Blur im Event-Sheet.
class BottomModalScrollTopBlurOverlay extends StatefulWidget {
  const BottomModalScrollTopBlurOverlay({
    super.key,
    required this.controller,
    required this.isFullyExpanded,
    required this.surfaceColor,
  });

  final ScrollController controller;
  final bool isFullyExpanded;
  final Color surfaceColor;

  @override
  State<BottomModalScrollTopBlurOverlay> createState() =>
      _BottomModalScrollTopBlurOverlayState();
}

class _BottomModalScrollTopBlurOverlayState
    extends State<BottomModalScrollTopBlurOverlay> {
  double _strength = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant BottomModalScrollTopBlurOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
      _strength = 0;
    } else if (oldWidget.isFullyExpanded != widget.isFullyExpanded) {
      _syncStrength(force: true);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    _syncStrength();
  }

  void _syncStrength({bool force = false}) {
    if (!widget.controller.hasClients) return;
    final next = bottomModalTopBlurStrength(
      isFullyExpanded: widget.isFullyExpanded,
      contentScrollOffset: widget.isFullyExpanded ? widget.controller.offset : 0,
    );
    if (!force && (next - _strength).abs() < 0.04) return;
    if (!mounted || next == _strength) return;
    setState(() => _strength = next);
  }

  @override
  Widget build(BuildContext context) {
    return BottomModalTopBlurOverlay(
      strength: _strength,
      surfaceColor: widget.surfaceColor,
    );
  }
}
