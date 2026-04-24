import 'package:flutter/material.dart';

final class EmailConfirmationLayoutMetrics {
  const EmailConfirmationLayoutMetrics({
    required this.footerLead,
    required this.footerTail,
    required this.topGap,
    required this.iconBodyGap,
    required this.headingBodyGap,
  });

  final double footerLead;
  final double footerTail;
  final double topGap;
  final double iconBodyGap;
  final double headingBodyGap;

  factory EmailConfirmationLayoutMetrics.fromContext(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    return EmailConfirmationLayoutMetrics(
      footerLead: (screenH * 0.055).clamp(20.0, 52.0),
      footerTail: (screenH * 0.022).clamp(10.0, 22.0),
      topGap: (screenH * 0.028).clamp(6.0, 24.0),
      iconBodyGap: (screenH * 0.02).clamp(12.0, 20.0),
      headingBodyGap: (screenH * 0.012).clamp(8.0, 14.0),
    );
  }
}

final class EmailConfirmationTextStyles {
  const EmailConfirmationTextStyles({
    required this.subheading,
    required this.body,
    required this.emailHighlight,
    required this.footerMuted,
    required this.footerLink,
    required this.accentColor,
  });

  final TextStyle subheading;
  final TextStyle body;
  final TextStyle emailHighlight;
  final TextStyle footerMuted;
  final TextStyle footerLink;
  final Color accentColor;

  factory EmailConfirmationTextStyles.fromContext(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bodyStyle =
        theme.textTheme.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant,
          height: 1.5,
          fontSize: 17,
        ) ??
        TextStyle(
          color: scheme.onSurfaceVariant,
          height: 1.5,
          fontSize: 17,
        );
    final footerMutedStyle =
        theme.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
          fontSize: 15,
          height: 1.45,
        ) ??
        TextStyle(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
          height: 1.45,
          fontSize: 15,
        );

    return EmailConfirmationTextStyles(
      subheading:
          theme.textTheme.titleLarge?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ) ??
          TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
      body: bodyStyle,
      emailHighlight: bodyStyle.copyWith(
        color: scheme.primary,
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.underline,
        decorationColor: scheme.primary,
      ),
      footerMuted: footerMutedStyle,
      footerLink: footerMutedStyle.copyWith(
        color: scheme.primary,
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.underline,
        decorationColor: scheme.primary,
      ),
      accentColor: scheme.primary,
    );
  }
}
