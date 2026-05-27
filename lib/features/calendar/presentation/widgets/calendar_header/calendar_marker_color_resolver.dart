import 'package:flutter/material.dart';

import '../../../domain/models/calendar_entry.dart';
import 'calendar_day_marker_pill.dart' show TimelineSegment;
import 'calendar_marker_color_palette.dart';

/// Strategy that decides which colour a [TimelineSegment] is rendered with
/// inside a `CalendarDayMarkerPill`.
///
/// Keeping the colour decision out of the widget lets us:
///   * Evolve the colouring rules (per-choir tinting, theming, accessibility
///     variants, …) without touching layout or rendering code.
///   * Inject a different resolver in tests or for previews.
///   * Compose colour rules on top of a swappable [CalendarMarkerColorPalette].
///
/// The resolver itself is intentionally **decoupled** from any UI / filter
/// state — callers boil their context (e.g. "the user has more than one
/// choir selected") down to a plain boolean before constructing it.
@immutable
abstract class CalendarMarkerColorResolver {
  const CalendarMarkerColorResolver();

  /// Returns the fill colour for [segment].
  Color colorFor(TimelineSegment segment);

  /// Standard resolver used by the marker pills.
  ///
  /// * [distinguishChoirs]: when `true`, choir-type **and** event-type
  ///   segments are tinted by their [BackendChoir] using
  ///   [CalendarMarkerColorPalette.byChoir]. When `false`, every segment
  ///   uses its plain per-type colour from [CalendarMarkerColorPalette.byType].
  ///   The caller decides the trigger — typically `true` once the user has
  ///   selected more than one choir in the calendar filter.
  /// * [palette]: the colour palette to read from. Pass a custom palette to
  ///   re-theme without subclassing.
  factory CalendarMarkerColorResolver.standard({
    bool distinguishChoirs = false,
    CalendarMarkerColorPalette palette = CalendarMarkerColorPalette.standard,
  }) {
    return ChoirAwareMarkerColorResolver(
      palette: palette,
      distinguishChoirs: distinguishChoirs,
      applyChoirColorToEvents: distinguishChoirs,
    );
  }
}

/// Default resolver implementation. Splits the decision into:
///   1. Should we distinguish choirs at all? ([distinguishChoirs])
///   2. If yes and the segment is a choir — or an event when
///      [applyChoirColorToEvents] is `true` — look up its colour in the
///      palette's `byChoir` map.
///   3. Otherwise, fall back to the per-type colour.
@immutable
class ChoirAwareMarkerColorResolver extends CalendarMarkerColorResolver {
  const ChoirAwareMarkerColorResolver({
    required this.palette,
    required this.distinguishChoirs,
    this.applyChoirColorToEvents = false,
  });

  final CalendarMarkerColorPalette palette;

  /// Master switch for choir-based tinting. When `false` the resolver
  /// always returns the per-type colour, regardless of [applyChoirColorToEvents].
  final bool distinguishChoirs;

  /// When `true`, event-type segments are tinted by their associated
  /// [BackendChoir] in addition to choir-type segments. This is the rule
  /// the app uses when the user has selected multiple choirs in the filter.
  final bool applyChoirColorToEvents;

  bool _shouldTintByChoir(CalendarEntryType type) {
    if (!distinguishChoirs) return false;
    return switch (type) {
      CalendarEntryType.choir => true,
      CalendarEntryType.event => applyChoirColorToEvents,
      CalendarEntryType.lesson ||
      CalendarEntryType.meal ||
      CalendarEntryType.breakType => false,
    };
  }

  @override
  Color colorFor(TimelineSegment segment) {
    if (_shouldTintByChoir(segment.type)) {
      final choirColor = palette.byChoir[segment.choir];
      if (choirColor != null) return choirColor;
    }
    return palette.byType[segment.type] ?? palette.fallback;
  }
}

/// Resolver that always uses the per-type colour regardless of context.
/// Useful when you want the most basic colouring or for unit tests.
@immutable
class TypeOnlyMarkerColorResolver extends CalendarMarkerColorResolver {
  const TypeOnlyMarkerColorResolver({
    this.palette = CalendarMarkerColorPalette.standard,
  });

  final CalendarMarkerColorPalette palette;

  @override
  Color colorFor(TimelineSegment segment) {
    return palette.byType[segment.type] ?? palette.fallback;
  }
}
