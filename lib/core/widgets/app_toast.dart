import 'package:flutter/material.dart';

import '../theme/app_color_schemes.dart';
import '../theme/theme_tokens.dart';

/// Semantik für farbige Toast-/SnackBar-Nachrichten.
enum AppToastKind {
  /// Rot — Fehler
  error,

  /// Grün — Erfolg
  success,

  /// Blau — Hinweis
  info,
}

/// Zeigt eine schwebende SnackBar im Toast-Stil: Leading-Icon, farbige Zeile, Schließen-Icon.
void showAppToast(
  BuildContext context,
  String message, {
  AppToastKind kind = AppToastKind.info,
}) {
  if (!context.mounted) return;
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;

  final (Color accent, IconData icon) = switch (kind) {
    AppToastKind.error => (scheme.error, Icons.error_outline_rounded),
    AppToastKind.success => (AppColorSchemes.toastSuccess, Icons.check_circle_outline_rounded),
    AppToastKind.info => (AppColorSchemes.toastInfo, Icons.info_outline_rounded),
  };

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      elevation: 6,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.m,
        0,
        AppSpacing.m,
        AppSpacing.m,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      backgroundColor: scheme.surfaceContainerHighest,
      showCloseIcon: true,
      closeIconColor: scheme.onSurfaceVariant.withValues(alpha: 0.85),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
