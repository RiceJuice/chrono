import 'dart:ui' show ImageFilter;

import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Frosted-Glass-Verlauf oben im Detail-Sheet — liegt unter dem Drag-Handle.
class BottomModalTopGlassBlend extends StatelessWidget {
  const BottomModalTopGlassBlend({
    super.key,
    required this.opacity,
  });

  final double opacity;

  static const double height = 96;

  static bool _useNativeLiquidGlass() {
    final isApple =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    return isApple && PlatformVersion.shouldUseNativeGlass;
  }

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0) {
      return const SizedBox.shrink();
    }

    final glassLayer = _useNativeLiquidGlass()
        ? _buildNativeGlass()
        : _buildFallbackBlur();

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
              child: glassLayer,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNativeGlass() {
    return LiquidGlassContainer(
      config: const LiquidGlassConfig(
        effect: CNGlassEffect.regular,
        shape: CNGlassEffectShape.rect,
        cornerRadius: 0,
        interactive: false,
      ),
      child: SizedBox(
        height: height,
        width: double.infinity,
      ),
    );
  }

  /// Fallback ohne native Liquid Glass — nur Blur, ohne sichtbare Tönung.
  Widget _buildFallbackBlur() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
      child: const ColoredBox(
        color: Color(0x01FFFFFF),
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
