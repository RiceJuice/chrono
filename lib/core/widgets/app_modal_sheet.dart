import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';

/// Etwas langsameres, weicheres Ein-/Ausblenden als Material-Default (~250 ms),
/// näher an typischen iOS-Sheet-Präsentationen.
const AnimationStyle kAppModalSheetMotion = AnimationStyle(
  duration: Duration(milliseconds: 300),
  reverseDuration: Duration(milliseconds: 300),
  curve: Cubic(0.25, 0.1, 0.25, 1.0),
  reverseCurve: Cubic(0.33, 0.0, 0.67, 1.0),
);

/// Einheitliche Konfiguration für alle App-Modals / Bottom-Sheets.
abstract final class AppModalSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget Function(BuildContext context) builder,
    bool isScrollControlled = true,
    bool useSafeArea = true,
    bool showDragHandle = false,
    AnimationStyle? sheetAnimationStyle,
    Color? barrierColor,
    Color? backgroundColor,
  }) {
    final theme = Theme.of(context);
    final sheetBg = backgroundColor ??
        theme.bottomSheetTheme.modalBackgroundColor ??
        theme.bottomSheetTheme.backgroundColor ??
        theme.colorScheme.surfaceContainer;

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      showDragHandle: showDragHandle,
      backgroundColor: sheetBg,
      barrierColor: barrierColor,
      sheetAnimationStyle: sheetAnimationStyle ?? kAppModalSheetMotion,
      builder: builder,
    );
  }
}

/// Opake Sheet-Hülle mit Squircle-Oberkante — ohne Blur (nur Form & Fläche).
class AppModalSheetChrome extends StatelessWidget {
  const AppModalSheetChrome({
    super.key,
    required this.child,
    this.constraints,
    this.color,
    this.clipTopCorners = true,
  });

  final Widget child;
  final BoxConstraints? constraints;
  final Color? color;
  final bool clipTopCorners;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = color ??
        theme.bottomSheetTheme.modalBackgroundColor ??
        theme.colorScheme.surfaceContainer;

    Widget surface = ColoredBox(color: bg, child: child);

    if (constraints != null) {
      surface = ConstrainedBox(constraints: constraints!, child: surface);
    }

    if (clipTopCorners) {
      surface = ClipSmoothRect(
        radius: AppSquircle.topSheet(AppRadius.sheet),
        child: surface,
      );
    }

    return surface;
  }
}
