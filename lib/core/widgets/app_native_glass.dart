import 'package:chronoapp/core/widgets/calendar_progressive_blur.dart';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inspire_blur/inspire_blur.dart';

/// Union-ID für zusammengehörige Glass-Elemente im Kalender-Suchmodus.
const String kCalendarSearchGlassUnionId = 'calendar-search';

/// Maximale Blur-Stärke für Glass-Pinned-Bars im Suchmodus.
const double kSearchGlassPinnedBarMaxSigma = 8;

/// Deckkraft der Tönung in Glass-Pinned-Bars.
const double kSearchGlassPinnedBarTintAlpha = 0.08;

/// Kurve für den Tint-Verlauf in Glass-Pinned-Bars.
const Curve kSearchGlassPinnedBarTintCurve = Curves.easeInSine;

/// Ob natives Liquid Glass auf dieser Plattform verfügbar ist (iOS/macOS 26+).
bool useNativeLiquidGlass() {
  final isApple = defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
  return isApple && PlatformVersion.shouldUseNativeGlass;
}

/// Ob die native iOS-Tab-Bar-Suche während des Suchmodus sichtbar bleibt.
bool useNativeIosTabBarSearch() {
  return defaultTargetPlatform == TargetPlatform.iOS &&
      PlatformVersion.shouldUseNativeGlass;
}

/// Einheitliche Tint-Werte für Suchmodul-Glass-Elemente.
Color searchGlassTint(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark
      ? Colors.white.withValues(alpha: 0.05)
      : Colors.white.withValues(alpha: 0.42);
}

/// [LiquidGlassConfig] für Suchmodul-Glass-Elemente.
LiquidGlassConfig searchGlassConfig(
  BuildContext context, {
  CNGlassEffectShape shape = CNGlassEffectShape.capsule,
  double? cornerRadius,
  bool interactive = false,
}) {
  return LiquidGlassConfig(
    effect: CNGlassEffect.regular,
    shape: shape,
    cornerRadius: cornerRadius,
    tint: searchGlassTint(context),
    interactive: interactive,
  );
}

/// Kompakte Glass-Pill mit Label und optionalem Löschen-Button.
class AppGlassChip extends StatelessWidget {
  const AppGlassChip({
    required this.label,
    super.key,
    this.onDeleted,
    this.onPressed,
    this.tooltip,
  });

  final Widget label;
  final VoidCallback? onDeleted;
  final VoidCallback? onPressed;
  final String? tooltip;

  static const double _height = 30;
  static const double _horizontalPadding = 10;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DefaultTextStyle(
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                fontSize: 13,
                color: scheme.onSurface.withValues(alpha: 0.92),
              ),
          child: label,
        ),
        if (onDeleted != null) ...[
          const SizedBox(width: 2),
          GestureDetector(
            onTap: onDeleted,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );

    final chip = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(_height / 2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
          child: SizedBox(
            height: _height,
            child: Center(child: content),
          ),
        ),
      ),
    );

    final wrapped = useNativeLiquidGlass()
        ? LiquidGlassContainer(
            config: searchGlassConfig(
              context,
              shape: CNGlassEffectShape.capsule,
              cornerRadius: _height / 2,
              interactive: true,
            ),
            child: chip,
          )
        : DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(_height / 2),
            ),
            child: chip,
          );

    if (tooltip == null) return wrapped;
    return Tooltip(message: tooltip!, child: wrapped);
  }
}

/// Progressiver Blur-Streifen für fixierte Such-Header und Day-Header.
class AppGlassPinnedBar extends StatelessWidget {
  const AppGlassPinnedBar({
    required this.child,
    super.key,
    this.height,
    this.strength = 1,
    this.includeBottomHairline = false,
  });

  final Widget child;
  final double? height;
  final double strength;
  final bool includeBottomHairline;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveStrength = strength.clamp(0.0, 1.0);

    if (!useNativeLiquidGlass() || effectiveStrength <= 0) {
      return ColoredBox(
        color: scheme.surface,
        child: child,
      );
    }

    final maxSigma = kSearchGlassPinnedBarMaxSigma * effectiveStrength;
    final tintAlpha = kSearchGlassPinnedBarTintAlpha * effectiveStrength;

    return ClipRect(
      child: Stack(
        fit: height != null ? StackFit.passthrough : StackFit.loose,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CalendarProgressiveBackdropBlur(
                config: calendarEventSheetTopBlurConfig(sigma: maxSigma),
                fadeCurve: kSearchGlassPinnedBarTintCurve,
                useRepaintBoundary: false,
                child: Inspire.tint.topToBottom(
                  color: scheme.surface,
                  opacity: tintAlpha,
                  extent: 1.0,
                  curve: kSearchGlassPinnedBarTintCurve,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          if (height != null)
            SizedBox(height: height, width: double.infinity, child: child)
          else
            child,
          if (includeBottomHairline)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Divider(
                height: 1,
                thickness: 1,
                color: scheme.onSurface.withValues(alpha: 0.08),
              ),
            ),
        ],
      ),
    );
  }
}
