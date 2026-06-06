import 'package:flutter/material.dart';

/// Feste Typografie & Abstände für das Event-Detail-Bottom-Sheet.
abstract final class EventBottomModalTypography {
  EventBottomModalTypography._();

  // — Layout —
  static const double contentHorizontal = 14;
  static const double contentTop = 8;
  static const double contentBottom = 16;

  /// Abstand oberhalb der Veranstaltungsort-Zeile (über dem Titel).
  static const double locationTop = 14;
  static const double gapAfterLocation = 4;
  static const double gapAfterTitle = 14;
  static const double gapAfterTime = 24;
  static const double gapSection = 18;
  static const double gapLabelBody = 3;
  static const double gapScheduleCards = 8;
  /// Abstand zwischen „Ablauf“-Zeile (inkl. Chips) und erster Karte.
  static const double gapAfterScheduleHeader = 14;
  /// Zusätzlicher Abstand vor dem nächsten Ablaufpunkt (Now-Anker).
  static const double scheduleNowAnchorLeadGap = 20;
  /// Höhe des scrollbaren Ablauf-Bereichs (60 % Bildschirm).
  static const double scheduleListViewportFraction = 0.6;

  static const double cardHorizontal = 12;
  static const double cardVertical = 8;
  static const double cardLocationLeft = 12;

  // — Ablauf-Filter-Chips —
  static const double filterChipFontSize = 15;
  static const EdgeInsets filterChipPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  static const double filterChipGap = 8;

  // — Schriftgrößen —
  static const double location = 15;
  static const double time = 18;
  static const double sectionLabel = 18;
  static const double body = 15;

  static const double scheduleCardTitle = 16;
  static const double scheduleCardBody = 15;
  static const double scheduleCardLocation = 16;
  static const double scheduleCardTime = 16;

  static TextStyle eventLocation(ColorScheme scheme) => TextStyle(
        fontSize: location,
        fontWeight: FontWeight.w400,
        height: 1.25,
        color: scheme.onSurfaceVariant,
      );

  static TextStyle eventTime(ColorScheme scheme) => TextStyle(
        fontSize: time,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: scheme.onSurface,
      );

  static TextStyle sectionLabelStyle(ColorScheme scheme) => TextStyle(
        fontSize: sectionLabel,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.3,
        color: scheme.onSurfaceVariant,
      );

  static TextStyle bodyStyle(ColorScheme scheme) => TextStyle(
        fontSize: body,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: scheme.onSurface,
      );

  static TextStyle scheduleSectionLabel(ColorScheme scheme) => TextStyle(
        fontSize: sectionLabel,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.3,
        color: scheme.onSurfaceVariant,
      );

  static TextStyle scheduleCardTitleStyle(ColorScheme scheme) => TextStyle(
        fontSize: scheduleCardTitle,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: scheme.onSurface,
      );

  static TextStyle scheduleCardBodyStyle(ColorScheme scheme) => TextStyle(
        fontSize: scheduleCardBody,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: scheme.onSurface,
      );

  static TextStyle scheduleCardLocationStyle(ColorScheme scheme) => TextStyle(
        fontSize: scheduleCardLocation,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: scheme.onSurface.withValues(alpha: 0.36),
      );

  static TextStyle scheduleCardTimeStyle(ColorScheme scheme) => TextStyle(
        fontSize: scheduleCardTime,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: scheme.onSurface.withValues(alpha: 0.54),
      );
}
