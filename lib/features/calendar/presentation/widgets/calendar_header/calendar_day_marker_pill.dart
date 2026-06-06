import 'dart:math' as math;

import 'package:chronoapp/core/database/backend_enums.dart';
import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:flutter/material.dart';
import '../../../domain/models/calendar_entry.dart';
import 'calendar_marker_color_palette.dart';
import 'calendar_marker_color_resolver.dart';

export 'calendar_marker_color_palette.dart';
export 'calendar_marker_color_resolver.dart';

/// Default earliest hour the timeline always covers (24h clock).
const _defaultTimelineStartHour = 10;

/// Default latest hour the timeline always covers (24h clock).
/// Keeps the visual scale consistent across normal days; the timeline
/// extends beyond this only when events actually run later.
const _defaultTimelineEndHour = 20;

/// Hard upper bound for the timeline. Events that run past midnight are
/// already split per day in [buildCalendarDayMarkers], so 24:00 is the
/// natural cap for a single day's pill.
const _absoluteTimelineEndMinute = Duration.minutesPerDay;

/// Minimum width (in logical pixels) a segment is rendered with so that
/// even very short events stay visible inside the pill.
const _minimumSegmentWidth = 8.0;

/// Maximum gap (in logical pixels) between two adjacent segments at which
/// they should still be visually fused. Anything wider stays as separate
/// rounded pills.
const _segmentFusionGap = 4.0;

/// A segment is considered "small" for fusion purposes when it is at most
/// this many logical pixels wide. Two close segments only fuse when at least
/// one of them is small — large bars stay as fully rounded pills.
const _smallSegmentFusionThreshold = 10.0;

/// Two segment bars count as horizontally overlapping when their intersection
/// is wider than this (logical pixels). Then they are laid out side-by-side
/// instead of stacked, so both stay visible.
const _horizontalOverlapEpsilon = 0.5;

/// Padding inside the pill between the rounded background and the segments.
const _pillContentInset = 1.5;

/// Fallback duration when an entry has no meaningful end time (DB `end_time`
/// is null and the mapper sets `endTime == startTime`).
const _defaultMarkerDuration = Duration(hours: 1);

DateTime normalizeCalendarDay(DateTime day) => AppDateTime.localDay(day);

Map<DateTime, CalendarDayMarkerData> buildCalendarDayMarkers(
  List<CalendarEntry> entries,
) {
  final rawSegmentsByDay = <DateTime, List<_RawTimelineSegment>>{};
  final idsByDay = <DateTime, Set<String>>{};

  for (final entry in entries) {
    if (entry.type == CalendarEntryType.lesson ||
        entry.type == CalendarEntryType.meal) {
      continue;
    }
    // Recurring choir rehearsals from calendar_series are shown in the
    // event list but should not contribute to day-marker pills.
    if (entry.type == CalendarEntryType.choir && entry.isRecurringInstance) {
      continue;
    }
    // Break entries use the multi-day range bar and must not appear in day pills.
    if (entry.type == CalendarEntryType.breakType) {
      continue;
    }
    final start = AppDateTime.toLocal(entry.startTime);
    var end = AppDateTime.toLocal(entry.endTime);
    if (!end.isAfter(start)) {
      end = start.add(_defaultMarkerDuration);
    }

    // Both choir- *and* event-type entries can carry a meaningful
    // [BackendChoir]: e.g. a concert tagged with a specific choir. We keep
    // it as-is so the colour resolver can tint either kind of segment by
    // its choir when the user has multiple choirs active in the filter.
    // Entries without a meaningful choir simply have [BackendChoir.unknown]
    // and end up in the same merge bucket they would have used before.
    final effectiveChoir = entry.choir;

    var dayStart = normalizeCalendarDay(start);
    final endDay = normalizeCalendarDay(end);
    while (!dayStart.isAfter(endDay)) {
      final nextDayStart = dayStart.add(const Duration(days: 1));
      final effectiveStart = start.isAfter(dayStart) ? start : dayStart;
      final effectiveEnd = end.isBefore(nextDayStart) ? end : nextDayStart;
      final startMinute = effectiveStart
          .difference(dayStart)
          .inMinutes
          .clamp(0, Duration.minutesPerDay)
          .toInt();
      final endMinute = effectiveEnd
          .difference(dayStart)
          .inMinutes
          .clamp(0, Duration.minutesPerDay)
          .toInt();
      if (endMinute > startMinute) {
        rawSegmentsByDay
            .putIfAbsent(dayStart, () => <_RawTimelineSegment>[])
            .add(
              _RawTimelineSegment(
                type: entry.type,
                choir: effectiveChoir,
                startMinute: startMinute,
                endMinute: endMinute,
              ),
            );
        idsByDay.putIfAbsent(dayStart, () => <String>{}).add(entry.id);
      }
      dayStart = nextDayStart;
    }
  }

  final result = <DateTime, CalendarDayMarkerData>{};
  for (final dayEntry in rawSegmentsByDay.entries) {
    final day = dayEntry.key;
    final mergedSegments = _mergeSegmentsByTypeAndChoir(dayEntry.value);
    if (mergedSegments.isEmpty) continue;

    const defaultStartMinute =
        _defaultTimelineStartHour * Duration.minutesPerHour;
    const defaultEndMinute = _defaultTimelineEndHour * Duration.minutesPerHour;

    final earliestSegmentStart = mergedSegments.fold<int>(
      defaultStartMinute,
      (earliest, segment) => math.min(earliest, segment.startMinute),
    );
    final latestSegmentEnd = mergedSegments.fold<int>(
      defaultEndMinute,
      (latest, segment) => math.max(latest, segment.endMinute),
    );

    final timelineStartMinute = earliestSegmentStart
        .clamp(0, _absoluteTimelineEndMinute)
        .toInt();
    final timelineEndMinute = latestSegmentEnd
        .clamp(timelineStartMinute, _absoluteTimelineEndMinute)
        .toInt();
    final timelineDurationMinutes = timelineEndMinute - timelineStartMinute;
    if (timelineDurationMinutes <= 0) continue;

    final segments = <TimelineSegment>[];
    for (final segment in mergedSegments) {
      final relativeStart = (segment.startMinute - timelineStartMinute)
          .clamp(0, timelineDurationMinutes)
          .toInt();
      final relativeEnd = (segment.endMinute - timelineStartMinute)
          .clamp(0, timelineDurationMinutes)
          .toInt();
      if (relativeEnd <= relativeStart) continue;
      segments.add(
        TimelineSegment(
          type: segment.type,
          choir: segment.choir,
          startMinute: relativeStart,
          endMinute: relativeEnd,
        ),
      );
    }
    if (segments.isEmpty) continue;

    // Paint longer segments first so shorter ones remain visible on top
    // when different-type segments share part of the timeline.
    segments.sort((a, b) {
      final durationComparison = b.durationMinutes.compareTo(a.durationMinutes);
      if (durationComparison != 0) return durationComparison;
      return a.startMinute.compareTo(b.startMinute);
    });

    final totalMinutes = segments.fold<int>(
      0,
      (sum, segment) => sum + segment.durationMinutes,
    );
    if (totalMinutes <= 0) continue;

    result[day] = CalendarDayMarkerData(
      totalMinutes: totalMinutes,
      eventCount: idsByDay[day]?.length ?? 0,
      timelineDurationMinutes: timelineDurationMinutes,
      segments: segments,
    );
  }

  return result;
}

/// Merges overlapping or adjacent segments that share the same
/// `(type, choir)` identity.
///
/// Why `(type, choir)` and not just `type`?
///   * Two segments of the same choir are visually indistinguishable —
///     merging them avoids drawing redundant overlapping bars.
///   * Two segments of *different* choirs need to stay separate so the
///     colour resolver can render each one in its own colour when the day
///     has multiple appointments.
///   * Different [CalendarEntryType]s are never merged anyway.
///
/// For non-choir entries the choir is normalised to [BackendChoir.unknown]
/// upstream, so they all merge as one group as before.
List<_RawTimelineSegment> _mergeSegmentsByTypeAndChoir(
  List<_RawTimelineSegment> segments,
) {
  if (segments.isEmpty) return const <_RawTimelineSegment>[];

  final byKey =
      <(CalendarEntryType, BackendChoir), List<_RawTimelineSegment>>{};
  for (final segment in segments) {
    if (segment.endMinute <= segment.startMinute) continue;
    byKey
        .putIfAbsent(
          (segment.type, segment.choir),
          () => <_RawTimelineSegment>[],
        )
        .add(segment);
  }

  final merged = <_RawTimelineSegment>[];
  for (final entry in byKey.entries) {
    final (type, choir) = entry.key;
    final sorted = entry.value
      ..sort((a, b) => a.startMinute.compareTo(b.startMinute));
    var currentStart = sorted.first.startMinute;
    var currentEnd = sorted.first.endMinute;
    for (var i = 1; i < sorted.length; i++) {
      final next = sorted[i];
      if (next.startMinute <= currentEnd) {
        currentEnd = math.max(currentEnd, next.endMinute);
      } else {
        merged.add(
          _RawTimelineSegment(
            type: type,
            choir: choir,
            startMinute: currentStart,
            endMinute: currentEnd,
          ),
        );
        currentStart = next.startMinute;
        currentEnd = next.endMinute;
      }
    }
    merged.add(
      _RawTimelineSegment(
        type: type,
        choir: choir,
        startMinute: currentStart,
        endMinute: currentEnd,
      ),
    );
  }
  return merged;
}

class CalendarDayMarkerData {
  const CalendarDayMarkerData({
    required this.totalMinutes,
    required this.eventCount,
    required this.timelineDurationMinutes,
    required this.segments,
  });

  final int totalMinutes;
  final int eventCount;
  final int timelineDurationMinutes;
  final List<TimelineSegment> segments;
}

class _RawTimelineSegment {
  const _RawTimelineSegment({
    required this.type,
    required this.choir,
    required this.startMinute,
    required this.endMinute,
  });

  final CalendarEntryType type;
  final BackendChoir choir;
  final int startMinute;
  final int endMinute;

  int get durationMinutes => endMinute - startMinute;
}

class TimelineSegment {
  const TimelineSegment({
    required this.type,
    required this.choir,
    required this.startMinute,
    required this.endMinute,
  });

  final CalendarEntryType type;

  /// Choir the segment belongs to. For non-choir segments this is always
  /// [BackendChoir.unknown] so that grouping/merging stays stable for
  /// non-choir types regardless of any incidental choir value carried by
  /// the underlying calendar entry.
  final BackendChoir choir;
  final int startMinute;
  final int endMinute;

  int get durationMinutes => endMinute - startMinute;
}

(bool, BackendChoir) _segmentIdentity(TimelineSegment s) =>
    (s.type == CalendarEntryType.choir, s.choir);

/// Mutable layout description for a single segment used during rendering.
///
/// We need it mutable because the fusion pass can shift edges (close gaps)
/// and toggle whether the left/right corners stay rounded.
class _SegmentLayout {
  _SegmentLayout({
    required this.segment,
    required this.left,
    required this.width,
    required this.naturalBarWidth,
  });

  final TimelineSegment segment;
  double left;
  double width;

  /// Width from duration on the timeline **before** [_minimumSegmentWidth]
  /// is applied; used to decide whether an overlap cluster is „tiny“ enough
  /// to merge into a single pill.
  final double naturalBarWidth;
  bool flattenLeft = false;
  bool flattenRight = false;

  double get right => left + width;
}

double _horizontalOverlapWidth(_SegmentLayout a, _SegmentLayout b) {
  return math.min(a.right, b.right) - math.max(a.left, b.left);
}

bool _layoutsHorizontallyOverlap(_SegmentLayout a, _SegmentLayout b) {
  return _horizontalOverlapWidth(a, b) > _horizontalOverlapEpsilon;
}

_SegmentLayout _pickRepresentativeLayout(Iterable<_SegmentLayout> group) {
  return group.reduce((a, b) {
    final da = a.segment.durationMinutes;
    final db = b.segment.durationMinutes;
    if (da != db) return da > db ? a : b;
    final sa = a.segment.startMinute;
    final sb = b.segment.startMinute;
    if (sa != sb) return sa < sb ? a : b;
    final ea = a.segment.endMinute;
    final eb = b.segment.endMinute;
    if (ea != eb) return ea < eb ? a : b;
    final c = a.segment.type.index.compareTo(b.segment.type.index);
    if (c != 0) return c < 0 ? a : b;
    return a.segment.choir.index <= b.segment.choir.index ? a : b;
  });
}

/// Splits a multi-segment overlap group into equal horizontal slices so each
/// bar stays visible when at least one appointment is not „tiny“ on the track.
void _layoutOverlapGroupSideBySide(
  List<_SegmentLayout> groupLayouts,
  double maxWidth,
) {
  groupLayouts.sort((a, b) {
    final s = a.segment.startMinute.compareTo(b.segment.startMinute);
    if (s != 0) return s;
    final e = a.segment.endMinute.compareTo(b.segment.endMinute);
    if (e != 0) return e;
    final t = a.segment.type.index.compareTo(b.segment.type.index);
    if (t != 0) return t;
    return a.segment.choir.index.compareTo(b.segment.choir.index);
  });

  var unionLeft = groupLayouts.first.left;
  var unionRight = groupLayouts.first.right;
  for (final L in groupLayouts.skip(1)) {
    unionLeft = math.min(unionLeft, L.left);
    unionRight = math.max(unionRight, L.right);
  }

  final k = groupLayouts.length;
  var slice = (unionRight - unionLeft) / k;
  if (slice < _minimumSegmentWidth) {
    slice = _minimumSegmentWidth;
  }

  var startLeft = unionLeft;
  final span = k * slice;
  if (startLeft + span > maxWidth) {
    startLeft = maxWidth - span;
  }
  if (startLeft < 0) {
    startLeft = 0;
    slice = math.min(slice, maxWidth / k);
  }

  for (var i = 0; i < k; i++) {
    groupLayouts[i].left = startLeft + i * slice;
    groupLayouts[i].width = slice;
    groupLayouts[i].flattenLeft = false;
    groupLayouts[i].flattenRight = false;
  }
}

/// Overlap-connected groups: if every member is „tiny“ ([naturalBarWidth] ≤
/// [_smallSegmentFusionThreshold]), collapse to **one** fully rounded pill
/// (union of bar bounds, colour from the longest appointment). Otherwise keep
/// side-by-side slices so larger overlaps stay readable.
List<_SegmentLayout> _resolveOverlappingLayouts(
  List<_SegmentLayout> layouts,
  double maxWidth,
) {
  final n = layouts.length;
  if (n <= 1 || maxWidth <= 0) return List<_SegmentLayout>.from(layouts);

  final parent = List<int>.generate(n, (i) => i);
  int find(int i) {
    while (parent[i] != i) {
      parent[i] = parent[parent[i]];
      i = parent[i];
    }
    return i;
  }

  void union(int a, int b) {
    final pa = find(a);
    final pb = find(b);
    if (pa != pb) parent[pa] = pb;
  }

  for (var i = 0; i < n; i++) {
    for (var j = i + 1; j < n; j++) {
      if (_layoutsHorizontallyOverlap(layouts[i], layouts[j])) {
        union(i, j);
      }
    }
  }

  final rootToGroup = <int, List<int>>{};
  for (var i = 0; i < n; i++) {
    rootToGroup.putIfAbsent(find(i), () => <int>[]).add(i);
  }
  for (final e in rootToGroup.values) {
    e.sort();
  }

  final processedRoots = <int>{};
  final out = <_SegmentLayout>[];

  for (var i = 0; i < n; i++) {
    final r = find(i);
    if (processedRoots.contains(r)) continue;
    processedRoots.add(r);

    final group = rootToGroup[r]!;
    if (group.length == 1) {
      out.add(layouts[group.first]);
      continue;
    }

    final groupLayouts = group.map((idx) => layouts[idx]).toList();
    final allNaturalSmall = groupLayouts.every(
      (L) => L.naturalBarWidth <= _smallSegmentFusionThreshold,
    );

    if (allNaturalSmall) {
      final rep = _pickRepresentativeLayout(groupLayouts);
      var unionLeft = groupLayouts
          .map((L) => L.left)
          .reduce(math.min);
      var unionRight = groupLayouts
          .map((L) => L.right)
          .reduce(math.max);
      var w = unionRight - unionLeft;
      w = math.max(w, _minimumSegmentWidth);
      if (unionLeft + w > maxWidth) {
        unionLeft = maxWidth - w;
      }
      unionLeft = math.max(0.0, unionLeft);

      out.add(
        _SegmentLayout(
          segment: rep.segment,
          left: unionLeft,
          width: w,
          naturalBarWidth: rep.naturalBarWidth,
        ),
      );
    } else {
      _layoutOverlapGroupSideBySide(groupLayouts, maxWidth);
      for (final idx in group) {
        out.add(layouts[idx]);
      }
    }
  }

  return out;
}

/// Computes the pixel layout for every visible segment, then runs a fusion
/// pass that visually merges small adjacent segments by closing the gap
/// between them and squaring off the touching edges.
///
/// The returned list keeps the original z-order from [segments] (longest
/// first), so shorter bars stay on top in the [Stack].
List<_SegmentLayout> _buildSegmentLayouts({
  required List<TimelineSegment> segments,
  required double maxWidth,
  required int timelineMinutes,
}) {
  if (segments.isEmpty || maxWidth <= 0 || timelineMinutes <= 0) {
    return const <_SegmentLayout>[];
  }

  final layouts = <_SegmentLayout>[];
  for (final segment in segments) {
    final naturalLeft = maxWidth * (segment.startMinute / timelineMinutes);
    final naturalWidth =
        maxWidth * (segment.durationMinutes / timelineMinutes);

    // Always render at least `_minimumSegmentWidth` so very short events
    // stay legible, but never wider than the pill itself.
    final segmentWidth = math.min(
      maxWidth,
      math.max(naturalWidth, _minimumSegmentWidth),
    );
    // Anchor at the natural start. If that would push the bar past the
    // right edge (e.g. a short event close to the timeline end), pull it
    // back so the full bar stays inside the pill instead of being clipped.
    final maxLeft = math.max(0.0, maxWidth - segmentWidth);
    final segmentLeft = math.max(0.0, math.min(naturalLeft, maxLeft));

    layouts.add(
      _SegmentLayout(
        segment: segment,
        left: segmentLeft,
        width: segmentWidth,
        naturalBarWidth: naturalWidth,
      ),
    );
  }

  final resolved = _resolveOverlappingLayouts(layouts, maxWidth);

  // Fusion pass: walk segments in left-to-right order and merge any small
  // pair that is close enough so the user perceives them as one shape.
  // Only fuse segments with the same visual identity so side-by-side
  // appointments from the overlap pass are not pulled together again.
  final byLeft = resolved.toList()
    ..sort((a, b) => a.left.compareTo(b.left));
  for (var i = 0; i < byLeft.length - 1; i++) {
    final left = byLeft[i];
    final right = byLeft[i + 1];
    final gap = right.left - left.right;

    if (_segmentIdentity(left.segment) != _segmentIdentity(right.segment)) {
      continue;
    }

    // Touching or overlapping bars: fusion would distort layout; tiny
    // overlaps are also skipped via [_layoutsHorizontallyOverlap].
    if (gap < 0 || _layoutsHorizontallyOverlap(left, right)) continue;

    if (gap > _segmentFusionGap) continue;

    final isSmallEnough = left.width <= _smallSegmentFusionThreshold ||
        right.width <= _smallSegmentFusionThreshold;
    if (!isSmallEnough) continue;

    if (gap > 0) {
      // Close the gap by extending both segments to meet at the midpoint.
      final midpoint = (left.right + right.left) / 2;
      final originalRightEnd = right.right;
      left.width = midpoint - left.left;
      right.left = midpoint;
      right.width = originalRightEnd - midpoint;
    }
    left.flattenRight = true;
    right.flattenLeft = true;
  }

  return resolved;
}

class CalendarDayMarkerPill extends StatelessWidget {
  const CalendarDayMarkerPill({
    super.key,
    this.marker,
    this.width = 28,
    this.height = 7,
    this.colorResolver,
    this.palette = CalendarMarkerColorPalette.standard,
  });

  final CalendarDayMarkerData? marker;
  final double width;
  final double height;

  /// Optional override for the colour decision logic. When `null`, the
  /// pill falls back to a plain per-type [CalendarMarkerColorResolver.standard]
  /// (no choir tinting). The choir-aware behaviour is opt-in: callers that
  /// know the relevant context (e.g. how many choirs are selected in the
  /// filter) construct the resolver themselves and pass it in.
  final CalendarMarkerColorResolver? colorResolver;

  /// Palette used to build the default resolver. Ignored if a
  /// [colorResolver] is supplied explicitly.
  final CalendarMarkerColorPalette palette;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final marker = this.marker;

    final pillBackground = Color.alphaBlend(
      Colors.white.withValues(alpha: 0.08),
      scheme.surfaceContainerHighest,
    );

    return Container(
      width: width + (_pillContentInset * 2),
      height: height + (_pillContentInset * 2),
      decoration: BoxDecoration(
        color: pillBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_pillContentInset),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            if (marker == null ||
                marker.segments.isEmpty ||
                marker.timelineDurationMinutes <= 0 ||
                maxWidth <= 0) {
              return const SizedBox.expand();
            }

            final timelineMinutes = marker.timelineDurationMinutes;
            final layouts = _buildSegmentLayouts(
              segments: marker.segments,
              maxWidth: maxWidth,
              timelineMinutes: timelineMinutes,
            );
            final resolver =
                colorResolver ??
                CalendarMarkerColorResolver.standard(palette: palette);

            return ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Stack(
                children: layouts
                    .map(
                      (layout) => Positioned(
                        left: layout.left,
                        top: 0,
                        bottom: 0,
                        width: layout.width,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: resolver.colorFor(layout.segment),
                            borderRadius: BorderRadius.horizontal(
                              left: layout.flattenLeft
                                  ? Radius.zero
                                  : const Radius.circular(999),
                              right: layout.flattenRight
                                  ? Radius.zero
                                  : const Radius.circular(999),
                            ),
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            );
          },
        ),
      ),
    );
  }
}
