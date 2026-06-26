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

/// Einstellungen: weiches Einblenden für Auswahl-Sheets, etwas langsamer als
/// [kAppModalSheetMotion] für ruhigeres Auftreten.
const AnimationStyle kSettingsChoiceSheetMotion = AnimationStyle(
  duration: Duration(milliseconds: 300),
  reverseDuration: Duration(milliseconds: 220),
  curve: Cubic(0.22, 1, 0.36, 1),
  reverseCurve: Cubic(0.4, 0, 1, 1),
);

/// Zählt offene App-Modals — zuverlässiger als [CNTabBarRouteObserver],
/// weil Bottom-Sheets nicht immer den Root-Navigator mit Observer treffen.
final class AppModalSheetTracker {
  AppModalSheetTracker._();

  static final ValueNotifier<int> depth = ValueNotifier(0);

  static void _acquire() {
    depth.value = depth.value + 1;
  }

  static void _release() {
    final next = depth.value - 1;
    depth.value = next < 0 ? 0 : next;
  }

  /// Blendet die Main-Navigation auf iOS Glass aus (wie bei [AppModalSheet.show]).
  ///
  /// Für Vollbild-Routen über der Shell, die kein Bottom-Sheet nutzen.
  static void retainMainNavigationHidden() => _acquire();

  static void releaseMainNavigationHidden() => _release();
}

/// Entfernt das Scaffold-Insets der Main-Navigation (und sonstiges Bottom-Padding),
/// damit Modals bis zum unteren Bildschirmrand reichen.
class AppModalSheetMediaScope extends StatelessWidget {
  const AppModalSheetMediaScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return MediaQuery(
      data: mediaQuery.copyWith(
        padding: mediaQuery.padding.copyWith(bottom: 0),
        viewPadding: mediaQuery.viewPadding.copyWith(bottom: 0),
      ),
      child: child,
    );
  }
}

/// Max-Höhe für kompakte Auswahl-Modals (Einstellungen etc.) — Inhaltshöhe
/// darunter, mit kleinem Bottom-Padding; darüber wird gescrollt.
BoxConstraints appModalChoiceSheetConstraints(BuildContext context) {
  final screenHeight = MediaQuery.sizeOf(context).height;
  return BoxConstraints(maxHeight: screenHeight * 0.7);
}

/// Feste Min-/Max-Höhe für große Modals (z. B. Kalender-Detail).
BoxConstraints appModalSheetHeightConstraints(
  BuildContext context, {
  double minHeightFraction = 0.7,
  double maxHeightFraction = 0.9,
}) {
  final screenHeight = MediaQuery.sizeOf(context).height;
  return BoxConstraints(
    minHeight: screenHeight * minHeightFraction,
    maxHeight: screenHeight * maxHeightFraction,
  );
}

/// Kleiner Abstand zwischen System-UI (Statusleiste/Notch) und Sheet-Oberkante.
const double kAppSheetGapBelowSystemUi = AppSpacing.xs;

/// Feste Sheet-Höhe für Lesson/Meal/Choir-Detail (70 % Bildschirm).
const double kAppDetailModalInitialSize = 0.7;

/// Event-Detail: etwas höher, damit Beschreibung und Ablauf sichtbar sind.
const double kAppEventModalInitialSize = 0.65;

/// Minimale Sheet-Höhe zum Herunterziehen / Schließen (Event smooth_sheets).
const double kAppEventModalMinSize = 0.35;

/// MediaQuery der physischen [View] — unabhängig vom Bottom-Sheet-[MediaQuery.padding].
MediaQueryData appSheetViewMediaQuery(BuildContext context) {
  return MediaQueryData.fromView(View.of(context));
}

/// Y-Position der Sheet-Oberkante: knapp unter Statusleiste/Notch.
///
/// Liegt damit über dem Kalender-[AppBar]-Titel (z. B. Monatsname).
double appSheetTopOffset(BuildContext context) {
  final view = appSheetViewMediaQuery(context);
  return view.viewPadding.top + kAppSheetGapBelowSystemUi;
}

/// Höhe eines Sheets, das von [appSheetTopOffset] bis zum unteren Bildschirmrand reicht.
double appSheetHeightBelowSystemUi(BuildContext context) {
  final view = appSheetViewMediaQuery(context);
  return view.size.height - appSheetTopOffset(context);
}

/// Aufgaben-Formular — hohes Sheet, Inhalt auf einer Seite.
BoxConstraints appModalHomeworkFormSheetConstraints(BuildContext context) {
  final screenHeight = MediaQuery.sizeOf(context).height;
  return BoxConstraints.tightFor(height: screenHeight * 0.88);
}

/// Termin-Formular (Erstellen & Bearbeiten).
BoxConstraints appModalEventFormSheetConstraints(BuildContext context) {
  return BoxConstraints.tightFor(
    height: appSheetHeightBelowSystemUi(context),
  );
}

/// Einheitliche Konfiguration für alle App-Modals / Bottom-Sheets.
abstract final class AppModalSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget Function(BuildContext context) builder,
    bool isScrollControlled = true,
    bool useSafeArea = false,
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

    AppModalSheetTracker._acquire();
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      // Root-Navigator: Sheet liegt über dem Shell-Scaffold inkl. bottomNavigationBar.
      // Ohne das landet die Route im Branch-Navigator unter der Main-Navigation.
      useRootNavigator: true,
      useSafeArea: false,
      showDragHandle: showDragHandle,
      backgroundColor: sheetBg,
      barrierColor: barrierColor,
      sheetAnimationStyle: sheetAnimationStyle ?? kAppModalSheetMotion,
      builder: (context) {
        Widget sheet = AppModalSheetMediaScope(child: builder(context));
        if (useSafeArea) {
          sheet = SafeArea(top: true, bottom: false, child: sheet);
        }
        return sheet;
      },
    ).whenComplete(AppModalSheetTracker._release);
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
