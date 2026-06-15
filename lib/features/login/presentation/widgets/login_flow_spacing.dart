import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:flutter/material.dart';

/// Responsive Abstände für den Login-Flow — proportional zur Viewport-Höhe,
/// mit kompakteren Werten auf kleinen Geräten.
abstract final class LoginFlowSpacing {
  /// Kurze Viewports (z. B. iPhone SE, kleine Android-Geräte).
  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).height < 700;

  static double _proportional(
    BuildContext context, {
    required double factor,
    required double min,
    required double max,
    double compactMaxFactor = 0.75,
  }) {
    final double h = MediaQuery.sizeOf(context).height;
    final double scaled = h * factor;
    final double effectiveMax =
        isCompact(context) ? max * compactMaxFactor : max;
    return scaled.clamp(min, effectiveMax);
  }

  static double gapAfterTopBar(BuildContext context) => _proportional(
        context,
        factor: 0.018,
        min: AppSpacing.s,
        max: 16,
      );

  static double gapAfterStepIndicator(BuildContext context) => _proportional(
        context,
        factor: 0.022,
        min: AppSpacing.m,
        max: 20,
      );

  static double gapBetweenFields(BuildContext context) => isCompact(context)
      ? AppSpacing.m
      : _proportional(
          context,
          factor: 0.018,
          min: AppSpacing.m,
          max: AppSpacing.l,
        );

  static double gapAfterFieldLabel(BuildContext context) =>
      isCompact(context) ? AppSpacing.xs : AppSpacing.s;

  static double gapAfterHeader(BuildContext context) => _proportional(
        context,
        factor: 0.018,
        min: AppSpacing.xs,
        max: AppSpacing.m,
      );

  static double gapBeforeFooter(BuildContext context) => _proportional(
        context,
        factor: 0.02,
        min: AppSpacing.m,
        max: AppSpacing.l,
      );

  static double gapAfterFooter(BuildContext context) => _proportional(
        context,
        factor: 0.012,
        min: AppSpacing.xs,
        max: AppSpacing.m,
      );

  static double gapBeforePrimaryButton(BuildContext context) => _proportional(
        context,
        factor: 0.012,
        min: AppSpacing.xs,
        max: AppSpacing.s,
      );

  /// Titelgröße für Schritt-Header — kleiner auf kompakten Screens.
  static double headerTitleSize(BuildContext context, {double desktop = 44}) {
    if (isCompact(context)) return 30;
    return desktop;
  }

  static double headerSubtitleSize(BuildContext context) =>
      isCompact(context) ? 14 : 16;
}
