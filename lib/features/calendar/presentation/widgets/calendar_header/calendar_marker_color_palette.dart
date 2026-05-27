import 'package:chronoapp/core/database/backend_enums.dart';
import 'package:flutter/material.dart';

import '../../../domain/models/calendar_entry.dart';

/// Configuration object that holds every colour used by the calendar
/// day-marker pills.
///
/// This file is the **single source of truth** for marker colours. To
/// re-theme the pills, change the palette below (or build your own and pass
/// it into the colour resolver). Neither the rendering code nor the
/// colour-resolution logic should ever hard-code a colour value — they read
/// it from a [CalendarMarkerColorPalette].
@immutable
class CalendarMarkerColorPalette {
  const CalendarMarkerColorPalette({
    required this.byType,
    required this.byChoir,
    required this.fallback,
  });

  /// Default colour per [CalendarEntryType]. Used whenever no more specific
  /// rule applies (e.g. a single appointment on a day).
  final Map<CalendarEntryType, Color> byType;

  /// Colour per individual [BackendChoir]. The resolver falls back to this
  /// map when it wants to distinguish multiple choirs on the same day at a
  /// glance.
  final Map<BackendChoir, Color> byChoir;

  /// Last-resort colour for unknown enum values or future additions that
  /// haven't been mapped yet.
  final Color fallback;

  /// Returns a copy of this palette with the given fields replaced.
  CalendarMarkerColorPalette copyWith({
    Map<CalendarEntryType, Color>? byType,
    Map<BackendChoir, Color>? byChoir,
    Color? fallback,
  }) {
    return CalendarMarkerColorPalette(
      byType: byType ?? this.byType,
      byChoir: byChoir ?? this.byChoir,
      fallback: fallback ?? this.fallback,
    );
  }

  /// The palette used by default throughout the app. Tweak these values to
  /// re-theme the marker pills.
  static const CalendarMarkerColorPalette standard = CalendarMarkerColorPalette(
    byType: <CalendarEntryType, Color>{
      CalendarEntryType.event: Color(0xFF29509E),
      CalendarEntryType.choir: Color(0xFFCBBBA0),
      // Lesson and meal segments are filtered out before reaching the pill,
      // but we keep them here for completeness so anyone re-using the
      // palette in another context still gets a sensible colour.
      CalendarEntryType.lesson: Color(0xFF124E30),
      CalendarEntryType.meal: Color(0xFF124E30),
      CalendarEntryType.breakType: Color(0xFF29509E),
    },
    byChoir: <BackendChoir, Color>{
      BackendChoir.dkm: Color(0xFFCBBBA0),
      BackendChoir.raedlinger: Color(0xFF124E30),
      BackendChoir.giehl: Color.fromARGB(255, 52, 108, 228),
      BackendChoir.szuczies: Color(0xFFE93609),
      BackendChoir.schola: Color.fromARGB(255, 0, 247, 255),
      BackendChoir.unknown: Color(0xFFCBBBA0),
    },
    fallback: Color(0xFF7F7F7F),
  );
}
