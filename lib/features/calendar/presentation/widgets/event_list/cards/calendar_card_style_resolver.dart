import 'package:flutter/material.dart';

import '../../../theme/calendar_presentation_theme.dart';
import 'calendar_entry_temporal_state.dart';

class CalendarCardStyle {
  const CalendarCardStyle({
    required this.cardBackgroundColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.timeTextColor,
    required this.imageOverlayOpacity,
  });

  final Color cardBackgroundColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color timeTextColor;
  final double imageOverlayOpacity;
}

class CalendarCardStyleResolver {
  CalendarCardStyleResolver._();

  /// Reines Schwarz oder Weiß je nach [background], für maximalen Kontrast auf der Kartenfläche.
  static Color highContrastOnBackground(Color background) {
    final brightness = ThemeData.estimateBrightnessForColor(background);
    return brightness == Brightness.dark ? Colors.white : Colors.black;
  }

  static CalendarCardStyle resolve({
    required BuildContext context,
    required Color baseBackgroundColor,
    required CalendarEntryTemporalState temporalState,
    bool applyPastStyling = false,
  }) {
    if (!applyPastStyling || !temporalState.isPast) {
      final scheme = Theme.of(context).colorScheme;
      final onCard = highContrastOnBackground(baseBackgroundColor);
      return CalendarCardStyle(
        cardBackgroundColor: baseBackgroundColor,
        primaryTextColor: onCard,
        secondaryTextColor: onCard.withValues(alpha: 0.82),
        timeTextColor: scheme.onSurface,
        imageOverlayOpacity: 0,
      );
    }

    return CalendarCardStyle(
      cardBackgroundColor: CalendarPresentationTheme.dimmedSurface(
        context,
        baseBackgroundColor,
      ),
      primaryTextColor: CalendarPresentationTheme.pastTextColor(context),
      secondaryTextColor: CalendarPresentationTheme.pastMutedTextColor(context),
      timeTextColor: CalendarPresentationTheme.pastTextColor(context),
      imageOverlayOpacity: 0.32,
    );
  }
}
