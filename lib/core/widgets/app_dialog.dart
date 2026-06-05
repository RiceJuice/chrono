import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/core/widgets/app_hairline_divider.dart';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Eckenradius für zentrierte Alerts — siehe [AppRadius.dialog].
const double kAppDialogRadius = AppRadius.dialog;

const Duration _kDialogMotionDuration = Duration(milliseconds: 260);
const Curve _kDialogMotionCurve = Cubic(0.25, 0.1, 0.25, 1.0);

/// Innenabstand für Dialog-Texte.
const EdgeInsets kAppDialogContentPadding = EdgeInsets.fromLTRB(28, 32, 28, 24);

/// Rolle einer Dialog-Aktion — steuert Typografie und Farbe (iOS-Alert-Stil).
enum AppDialogActionRole {
  cancel,
  normal,
  primary,
  destructive,
}

/// Einheitliche Typografie für Dialog-Inhalte.
abstract final class AppDialogTypography {
  AppDialogTypography._();

  static TextStyle title(ThemeData theme) {
    return theme.dialogTheme.titleTextStyle ??
        theme.textTheme.titleLarge!.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          height: 1.2,
          color: theme.colorScheme.onSurface,
        );
  }

  static TextStyle message(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return theme.textTheme.bodyMedium!.copyWith(
      fontSize: 15,
      letterSpacing: -0.24,
      height: 1.47,
      color: theme.colorScheme.onSurface.withValues(
        alpha: isDark ? 0.72 : 0.68,
      ),
    );
  }

  /// Einleitungstext — etwas kräftiger als [message].
  static TextStyle lead(ThemeData theme) {
    return theme.textTheme.bodyMedium!.copyWith(
      fontSize: 15,
      letterSpacing: -0.24,
      height: 1.47,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.88),
    );
  }

  /// Erklärung oder Zusatzinfo unter der Einleitung.
  static TextStyle hint(ThemeData theme) {
    return theme.textTheme.bodySmall!.copyWith(
      fontSize: 13,
      letterSpacing: -0.08,
      height: 1.5,
      color: theme.colorScheme.onSurfaceVariant,
    );
  }

  /// Kleine Überschrift über Listen (z. B. Änderungsvorschau).
  static TextStyle sectionLabel(ThemeData theme) {
    return theme.textTheme.labelMedium!.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      height: 1.3,
      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
    );
  }

  static TextStyle listItem(ThemeData theme) {
    return theme.textTheme.bodySmall!.copyWith(
      fontSize: 13,
      letterSpacing: -0.08,
      height: 1.45,
      color: theme.colorScheme.onSurfaceVariant,
    );
  }
}

/// Beschreibt eine tappbare Dialog-Aktion.
class AppDialogAction<T> {
  const AppDialogAction({
    required this.label,
    this.role = AppDialogActionRole.normal,
    this.value,
    this.onPressed,
  });

  final String label;
  final AppDialogActionRole role;
  final T? value;
  final VoidCallback? onPressed;
}

bool _useNativeLiquidGlass() {
  final isApple =
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
  return isApple && PlatformVersion.shouldUseNativeGlass;
}

/// Zeigt einen App-weiten Bestätigungsdialog (zwei Aktionen).
Future<bool> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  String? message,
  Widget? content,
  String confirmLabel = 'OK',
  String cancelLabel = 'Abbrechen',
  AppDialogActionRole confirmRole = AppDialogActionRole.primary,
  bool barrierDismissible = true,
}) async {
  final result = await showAppDialog<bool>(
    context: context,
    title: title,
    message: message,
    content: content,
    barrierDismissible: barrierDismissible,
    actions: [
      AppDialogAction<bool>(
        label: cancelLabel,
        role: AppDialogActionRole.cancel,
        value: false,
        onPressed: () => AppHaptics.selection(),
      ),
      AppDialogAction<bool>(
        label: confirmLabel,
        role: confirmRole,
        value: true,
        onPressed: () => AppHaptics.medium(),
      ),
    ],
  );
  return result ?? false;
}

/// Zeigt einen modernen, Apple-inspirierten Dialog mit optionalem Liquid Glass.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required String title,
  String? message,
  Widget? content,
  List<AppDialogAction<T>> actions = const [],
  bool barrierDismissible = true,
  TextAlign messageAlign = TextAlign.center,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.28),
    transitionDuration: _kDialogMotionDuration,
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return Center(
        child: AppDialog<T>(
          title: title,
          message: message,
          content: content,
          actions: actions,
          messageAlign: messageAlign,
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: _kDialogMotionCurve,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Inhalt eines [showAppDialog]-Aufrufs.
class AppDialog<T> extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.actions = const [],
    this.messageAlign = TextAlign.center,
  });

  final String title;
  final String? message;
  final Widget? content;
  final List<AppDialogAction<T>> actions;
  final TextAlign messageAlign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxWidth = MediaQuery.sizeOf(context).width - 48;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth.clamp(0, 340)),
        child: AppDialogSurface(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: kAppDialogContentPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppDialogTypography.title(theme),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: AppSpacing.l),
                      Text(
                        message!,
                        textAlign: messageAlign,
                        style: AppDialogTypography.message(theme),
                      ),
                    ],
                    if (content != null) ...[
                      if (message != null) const SizedBox(height: AppSpacing.m),
                      content!,
                    ],
                  ],
                ),
              ),
              if (actions.isNotEmpty) ...[
                const AppHairlineDivider.horizontal(),
                _AppDialogActions<T>(actions: actions),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog-Hülle — natives Liquid Glass auf iOS 26+, Theme-Farbe sonst.
class AppDialogSurface extends StatelessWidget {
  const AppDialogSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (_useNativeLiquidGlass()) {
      return _NativeDialogSurface(child: child);
    }
    return _ThemedDialogSurface(child: child);
  }
}

class _NativeDialogSurface extends StatelessWidget {
  const _NativeDialogSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LiquidGlassContainer(
      config: LiquidGlassConfig(
        effect: CNGlassEffect.regular,
        shape: CNGlassEffectShape.rect,
        cornerRadius: kAppDialogRadius,
        tint: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.42),
      ),
      child: child,
    );
  }
}

/// Opake Theme-Oberfläche für Android und älteres iOS.
class _ThemedDialogSurface extends StatelessWidget {
  const _ThemedDialogSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background =
        theme.dialogTheme.backgroundColor ?? scheme.surfaceContainerHigh;

    return Material(
      color: background,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: AppSquircle.shape(kAppDialogRadius),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _AppDialogActions<T> extends StatelessWidget {
  const _AppDialogActions({required this.actions});

  final List<AppDialogAction<T>> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const AppHairlineDivider.horizontal(),
          _AppDialogActionButton(action: actions[i]),
        ],
      ],
    );
  }
}

class _AppDialogActionButton<T> extends StatelessWidget {
  const _AppDialogActionButton({required this.action});

  final AppDialogAction<T> action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final isDark = scheme.brightness == Brightness.dark;
    final Color foreground = switch (action.role) {
      AppDialogActionRole.destructive => scheme.error,
      // Akzentfarbe (#CBBBA0) hat auf hellem Glass zu wenig Kontrast.
      AppDialogActionRole.primary =>
        isDark ? scheme.primary : scheme.secondary,
      AppDialogActionRole.cancel =>
        scheme.onSurface.withValues(alpha: isDark ? 0.62 : 0.55),
      AppDialogActionRole.normal => scheme.onSurface,
    };

    final fontWeight = action.role == AppDialogActionRole.primary ||
            action.role == AppDialogActionRole.destructive
        ? FontWeight.w600
        : FontWeight.w500;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        splashColor: scheme.onSurface.withValues(alpha: 0.06),
        highlightColor: scheme.onSurface.withValues(alpha: 0.04),
        onTap: () {
          action.onPressed?.call();
          Navigator.of(context).pop<T>(action.value);
        },
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
              child: Text(
                action.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 17,
                  color: foreground,
                  fontWeight: fontWeight,
                  letterSpacing: -0.41,
                  height: 1.15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
