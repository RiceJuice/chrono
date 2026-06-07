import 'package:flutter/material.dart';

/// Feste Typografie & Abstände für das Event-Detail-Bottom-Sheet.
abstract final class EventBottomModalTypography {
  EventBottomModalTypography._();

  // — Layout —
  /// Ein Wert für den Event-Bild-Header: Rand-Abstand, Abstand zwischen Bildern
  /// und Basis für den inneren Eckenradius (Sheet-Radius minus dieser Wert).
  static const double imageHeaderSpacing = 6;

  static const double contentHorizontal = 20;
  static const double contentTop = 4;
  static const double contentBottom = 24;

  /// Kleiner Abstand zwischen Titel und Untertitel/Beschreibung.
  static const double gapAfterTitle = 8;

  /// Einheitlicher, großzügiger Abstand zwischen den Hauptblöcken
  /// (Titel/Beschreibung ↔ Eckdaten ↔ Notiz ↔ Ablauf).
  static const double gapSection = 28;

  /// Abstand zwischen den Eckdaten-Zeilen (Datum/Uhrzeit ↔ Ort).
  static const double gapInlineInfoRows = 2;
  static const double inlineInfoIconSize = 16;
  static const double inlineInfoIconGap = 12;
  static const double gapLabelBody = 8;
  static const double gapScheduleCards = 8;
  /// Abstand zwischen „Ablauf“-Zeile (inkl. Chips) und erster Karte.
  static const double gapAfterScheduleHeader = 14;
  /// Zusätzlicher Abstand vor dem nächsten Ablaufpunkt (Now-Anker).
  static const double scheduleNowAnchorLeadGap = 12;
  /// Höhe des scrollbaren Ablauf-Bereichs (60 % Bildschirm).
  static const double scheduleListViewportFraction = 0.6;

  static const double cardHorizontal = 12;
  static const double cardVertical = 8;
  static const double cardLocationLeft = 12;
  static const double scheduleCardTitleBodyGap = 3;
  static const double scheduleCardBodyLocationGap = 8;

  // — Ablauf-Filter-Chips —
  static const double filterChipFontSize = 15;
  static const EdgeInsets filterChipPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 4);
  static const double filterChipGap = 8;

  // — Schriftgrößen —
  static const double subtitle = 15;
  static const double inlineInfo = 15;
  static const double sectionLabel = 13;
  static const double body = 15;

  static const double scheduleCardTitle = 15;
  static const double scheduleCardBody = 15;
  static const double scheduleCardLocation = 14;
  static const double scheduleCardTime = 16;

  static TextStyle inlineInfoStyle(ColorScheme scheme) => TextStyle(
        fontSize: inlineInfo,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: scheme.onSurface,
      );

  static TextStyle eventSubtitle(ColorScheme scheme) => TextStyle(
        fontSize: subtitle,
        fontWeight: FontWeight.w300,
        height: 1.35,
        color: scheme.onSurfaceVariant,
      );

  static TextStyle sectionLabelStyle(ColorScheme scheme) => TextStyle(
        fontSize: sectionLabel,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.6,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
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
        letterSpacing: 0.6,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
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
