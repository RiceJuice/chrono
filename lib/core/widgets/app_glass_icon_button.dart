import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Skaliert die Glyphen leicht hoch, damit Striche auf dem Glass-Kreis
/// kräftiger wirken (SF Symbols nutzen sonst nur Regular-Gewicht).
const double _kGlassIconInkScale = 1.12;

/// Runder Icon-Button mit nativem Liquid Glass (iOS/macOS 26+) oder
/// Material-Kreis-Fallback auf anderen Plattformen.
class AppGlassIconButton extends StatelessWidget {
  const AppGlassIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.enabled = true,
    this.iconSize = 18,
    this.child,
    this.materialBackgroundColor,
    this.glassEffectUnionId,
    this.glassEffectId,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool enabled;
  final double iconSize;

  /// Ersetzt das Icon (z. B. Lade-Spinner) — erzwingt Material-Fallback.
  final Widget? child;

  /// Hintergrund nur im Material-Fallback; Standard: halbtransparentes Surface.
  final Color? materialBackgroundColor;

  /// Optional: gemeinsame Glass-Union für gruppierte Effekte (iOS 26+).
  final String? glassEffectUnionId;

  /// Optional: Glass-Morph-ID (iOS 26+).
  final String? glassEffectId;

  static bool _useNativeGlass() {
    final isApple =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    return isApple && PlatformVersion.shouldUseNativeGlass;
  }

  static double _visualIconSize(double iconSize) => iconSize * _kGlassIconInkScale;

  /// Icon für Akzent-/Farbeinstellungen auf Glass-Buttons.
  static const IconData accentColorIcon = Icons.brush_outlined;

  static CNSymbol? _sfSymbolFor(IconData icon, double size, Color color) {
    final visualSize = _visualIconSize(size);
    if (icon == Icons.close) {
      return CNSymbol('xmark', size: visualSize, color: color);
    }
    if (icon == Icons.check) {
      return CNSymbol('checkmark', size: visualSize, color: color);
    }
    if (icon == accentColorIcon || icon == Icons.brush) {
      return CNSymbol('paintbrush', size: visualSize, color: color);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = scheme.onSurface;
    final effectiveEnabled = enabled && onPressed != null;

    final button = child != null || !_useNativeGlass()
        ? _MaterialCircleIconButton(
            icon: icon,
            iconSize: iconSize,
            foregroundColor: foreground,
            backgroundColor:
                materialBackgroundColor ??
                scheme.surface.withValues(alpha: 0.92),
            onPressed: effectiveEnabled ? onPressed : null,
            child: child,
          )
        : _NativeGlassIconButton(
            icon: icon,
            iconSize: iconSize,
            tint: foreground,
            onPressed: onPressed,
            enabled: enabled,
            glassEffectUnionId: glassEffectUnionId,
            glassEffectId: glassEffectId,
          );

    return Tooltip(message: tooltip, child: button);
  }
}

class _NativeGlassIconButton extends StatelessWidget {
  const _NativeGlassIconButton({
    required this.icon,
    required this.iconSize,
    required this.tint,
    required this.onPressed,
    required this.enabled,
    this.glassEffectUnionId,
    this.glassEffectId,
  });

  final IconData icon;
  final double iconSize;
  final Color tint;
  final VoidCallback? onPressed;
  final bool enabled;
  final String? glassEffectUnionId;
  final String? glassEffectId;

  @override
  Widget build(BuildContext context) {
    final sfSymbol = AppGlassIconButton._sfSymbolFor(icon, iconSize, tint);

    if (sfSymbol != null) {
      return CNButton.icon(
        icon: sfSymbol,
        onPressed: onPressed,
        enabled: enabled,
        tint: tint,
        config: CNButtonConfig(
          style: CNButtonStyle.glass,
          customIconSize: AppGlassIconButton._visualIconSize(iconSize),
          glassEffectUnionId: glassEffectUnionId,
          glassEffectId: glassEffectId,
        ),
      );
    }

    return CNButton.icon(
      icon: CNSymbol('xmark', size: AppGlassIconButton._visualIconSize(iconSize), color: tint),
      customIcon: icon,
      onPressed: onPressed,
      enabled: enabled,
      tint: tint,
      config: CNButtonConfig(
        style: CNButtonStyle.glass,
        customIconSize: AppGlassIconButton._visualIconSize(iconSize),
        glassEffectUnionId: glassEffectUnionId,
        glassEffectId: glassEffectId,
      ),
    );
  }
}

class _MaterialCircleIconButton extends StatelessWidget {
  const _MaterialCircleIconButton({
    required this.icon,
    required this.iconSize,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.onPressed,
    this.child,
  });

  final IconData icon;
  final double iconSize;
  final Color foregroundColor;
  final Color backgroundColor;
  final VoidCallback? onPressed;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          foregroundColor: foregroundColor,
          padding: const EdgeInsets.all(12),
        ),
        onPressed: onPressed,
        icon: child ??
            Icon(
              icon,
              size: AppGlassIconButton._visualIconSize(iconSize),
            ),
      ),
    );
  }
}
