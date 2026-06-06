import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Frosted-Glass-Verlauf oben im Detail-Sheet — liegt unter dem Drag-Handle.
class BottomModalTopGlassBlend extends StatelessWidget {
  const BottomModalTopGlassBlend({
    super.key,
    required this.opacity,
  });

  final double opacity;

  static const double height = 96;
  static const double _blurSigma = 52;

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = isDark
        ? Colors.black.withValues(alpha: 0.72)
        : Colors.black.withValues(alpha: 0.52);

    return IgnorePointer(
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: ClipRect(
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFFFF), Color(0x00000000)],
                stops: [0.0, 1.0],
              ).createShader(bounds),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: _blurSigma,
                  sigmaY: _blurSigma,
                ),
                child: ColoredBox(color: tint),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Scroll-Fortschritt (px), ab dem der Glas-Verlauf voll sichtbar ist.
const double kBottomModalTopGlassBlendFadeDistance = 36;

double bottomModalTopGlassBlendOpacity({
  required bool isFullyExpanded,
  required double contentScrollOffset,
}) {
  if (!isFullyExpanded || contentScrollOffset <= 0) {
    return 0;
  }
  return (contentScrollOffset / kBottomModalTopGlassBlendFadeDistance)
      .clamp(0.0, 1.0);
}
