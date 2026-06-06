import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:gradient_blur/gradient_blur.dart';

/// Feste Höhe des Blur-Streifens ganz oben im Sheet.
const double kBottomModalTopBlurOverlayHeight = 112;

/// Maximale Blur-Stärke (σ) im Streifen.
const double kBottomModalTopBlurMaxSigma = 4;

/// Deckkraft der Sheet-Hintergrundfarbe oben (0…1).
const double kBottomModalTopBlurTintAlpha = 0.5;

/// Scroll-Distanz (px), bis der Blur voll eingeblendet ist.
const double kBottomModalTopBlurFadeScrollDistance = 36;

/// Stärke 0…1 für den Top-Blur (Vollbild + gescrollt).
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

/// Fester Blur-Streifen oben — blurrt nur den Scroll-Inhalt darunter (BackdropFilter).
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
            slices: 14,
            curve: Curves.easeOutCubic,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                surfaceColor.withValues(alpha: tintAlpha),
                surfaceColor.withValues(alpha: 0),
              ],
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

/// Scroll-gesteuerter Top-Blur als festes Overlay.
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
  double _offset = 0;

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
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!widget.controller.hasClients) return;
    final offset = widget.controller.offset;
    if (offset == _offset) return;
    setState(() => _offset = offset);
  }

  @override
  Widget build(BuildContext context) {
    return BottomModalTopBlurOverlay(
      strength: bottomModalTopBlurStrength(
        isFullyExpanded: widget.isFullyExpanded,
        contentScrollOffset: widget.isFullyExpanded ? _offset : 0,
      ),
      surfaceColor: widget.surfaceColor,
    );
  }
}
