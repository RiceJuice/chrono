import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/providers/filter/calendar/calendar_filtered_entries_providers.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/calendar_entry_card.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/event_list.dart'
    show kBottomModalHeaderHeight;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Graustufen (Luminanz) — alle nicht ausgewählten Karten gleich behandelt.
const ColorFilter _kGrayscale = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
]);

const double _kMutedCardOpacity = 0.28;

/// Vertikaler Abstand zwischen allen Karten in der Vorschau-Liste.
const double _kModalCardSpacing = AppSpacing.m;

/// Größere Vorschau-Karten im Sheet-Header (Innenabstand + Titel).
const EdgeInsets _kModalPreviewCardPadding = EdgeInsets.symmetric(
  horizontal: AppSpacing.m,
  vertical: AppSpacing.l,
);
const double _kModalPreviewTitleFontSize = 17.5;

/// Zusätzlicher Abstand oberhalb der Liste, wenn der erste sichtbare Eintrag
/// der chronologisch erste Termin des lokalen Tages ist.
const double _kFirstOfDayModalListExtraTop = 24;

/// Vertikaler Masken-Verlauf ([ShaderMask]): Basis-Stops (Mitte = volle Sicht).
const double _kModalListEdgeFadeIn = 0.32;
const double _kModalListEdgeFadeOut = 0.68;

/// Wenn oberhalb / unterhalb des ausgewählten Eintrags keine weiteren Karten
/// in der Vorschau sind: kürzere Ausblendzone an dieser Kante (Termin „beginnt“
/// bzw. „endet“ dort).
const double _kModalListEdgeFadeShortIn = 0.16;
const double _kModalListEdgeFadeShortOut = 0.84;

class BottomModalHeader extends ConsumerWidget {
  final CalendarEntry entry;
  final double height;

  const BottomModalHeader({
    super.key,
    required this.entry,
    this.height = kBottomModalHeaderHeight,
  });

  static DateTime _localDayStart(CalendarEntry anchor) {
    final local = anchor.startTime.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static CalendarEntry? _firstEntryOfLocalDay(
    List<CalendarEntry> dayEntries,
    DateTime dayStart,
  ) {
    if (dayEntries.isEmpty) return null;
    final y = dayStart.year;
    final m = dayStart.month;
    final d = dayStart.day;
    final sameDay = dayEntries.where((e) {
      final s = e.startTime.toLocal();
      return s.year == y && s.month == m && s.day == d;
    }).toList();
    if (sameDay.isEmpty) return null;
    sameDay.sort((a, b) => a.startTime.compareTo(b.startTime));
    return sameDay.first;
  }

  static List<CalendarEntry> _entriesStartingAtLocalHour(
    List<CalendarEntry> dayEntries,
    DateTime dayStart,
    int hour,
  ) {
    if (hour < 0 || hour > 23) return [];
    final y = dayStart.year;
    final m = dayStart.month;
    final d = dayStart.day;
    final filtered = dayEntries.where((e) {
      final s = e.startTime.toLocal();
      return s.year == y && s.month == m && s.day == d && s.hour == hour;
    }).toList();
    filtered.sort((a, b) => a.startTime.compareTo(b.startTime));
    return filtered;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = AppDateTime.localDay(entry.startTime);
    final entriesAsync = ref.watch(filteredCalendarEntriesForDayProvider(day));
    final scheme = Theme.of(context).colorScheme;
    final headerH = height;

    return SizedBox(
      height: headerH,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: entry.accentColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.xl),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return entriesAsync.when(
                    data: (dayEntries) {
                      final dayStart = _localDayStart(entry);
                      final h = entry.startTime.toLocal().hour;

                      var curr =
                          _entriesStartingAtLocalHour(dayEntries, dayStart, h);
                      if (curr.isEmpty) {
                        curr = [entry];
                      }
                      final prev = _entriesStartingAtLocalHour(
                        dayEntries,
                        dayStart,
                        h - 1,
                      );
                      final next = _entriesStartingAtLocalHour(
                        dayEntries,
                        dayStart,
                        h + 1,
                      );

                      final selectedIdx =
                          curr.indexWhere((e) => e.id == entry.id);
                      final ix = selectedIdx >= 0 ? selectedIdx : 0;
                      final selected = curr[ix];
                      final beforeSel = curr.sublist(0, ix);
                      final afterSel = curr.sublist(ix + 1, curr.length);
                      final firstOfDay =
                          _firstEntryOfLocalDay(dayEntries, dayStart);

                      final orderedPreview = <CalendarEntry>[
                        ...prev,
                        ...beforeSel,
                        selected,
                        ...afterSel,
                        ...next,
                      ];
                      final si = orderedPreview.indexWhere(
                        (e) => e.id == selected.id,
                      );
                      final hasNeighborBefore =
                          si > 0 && orderedPreview.isNotEmpty;
                      final hasNeighborAfter = si >= 0 &&
                          si < orderedPreview.length - 1;

                      return _ModalHeaderEntryList(
                        viewportHeight: constraints.maxHeight,
                        prevHourEntries: prev,
                        beforeSelectedSameHour: beforeSel,
                        selected: selected,
                        afterSelectedSameHour: afterSel,
                        nextHourEntries: next,
                        firstEntryOfDay: firstOfDay,
                        hasNeighborBefore: hasNeighborBefore,
                        hasNeighborAfter: hasNeighborAfter,
                        applyPastStyling:
                            AppDateTime.isTodayLocal(curr.first.startTime),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  );
                },
              ),
            ),
            // Handle über der Liste, damit darunterliegende (gedimmte) Karten erlaubt sind.
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chronologische Vorschau; der **ausgewählte** Eintrag wird per
/// [Scrollable.ensureVisible] immer vertikal zentriert (Alignment 0.5).
/// Rand-Padding = ¼ Viewport-Höhe. Handle liegt über der Liste.
class _ModalHeaderEntryList extends StatefulWidget {
  final double viewportHeight;
  final List<CalendarEntry> prevHourEntries;
  final List<CalendarEntry> beforeSelectedSameHour;
  final CalendarEntry selected;
  final List<CalendarEntry> afterSelectedSameHour;
  final List<CalendarEntry> nextHourEntries;
  final CalendarEntry? firstEntryOfDay;
  final bool hasNeighborBefore;
  final bool hasNeighborAfter;
  final bool applyPastStyling;

  const _ModalHeaderEntryList({
    required this.viewportHeight,
    required this.prevHourEntries,
    required this.beforeSelectedSameHour,
    required this.selected,
    required this.afterSelectedSameHour,
    required this.nextHourEntries,
    required this.firstEntryOfDay,
    required this.hasNeighborBefore,
    required this.hasNeighborAfter,
    required this.applyPastStyling,
  });

  @override
  State<_ModalHeaderEntryList> createState() => _ModalHeaderEntryListState();
}

class _ModalHeaderEntryListState extends State<_ModalHeaderEntryList> {
  final GlobalKey _selectedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scheduleCenterSelected();
  }

  @override
  void didUpdateWidget(covariant _ModalHeaderEntryList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected.id != widget.selected.id ||
        oldWidget.viewportHeight != widget.viewportHeight ||
        oldWidget.firstEntryOfDay?.id != widget.firstEntryOfDay?.id ||
        oldWidget.hasNeighborBefore != widget.hasNeighborBefore ||
        oldWidget.hasNeighborAfter != widget.hasNeighborAfter ||
        !_sameEntryIds(_ordered(oldWidget), _ordered(widget))) {
      _scheduleCenterSelected();
    }
  }

  List<CalendarEntry> _ordered(_ModalHeaderEntryList w) {
    return <CalendarEntry>[
      ...w.prevHourEntries,
      ...w.beforeSelectedSameHour,
      w.selected,
      ...w.afterSelectedSameHour,
      ...w.nextHourEntries,
    ];
  }

  bool _sameEntryIds(List<CalendarEntry> a, List<CalendarEntry> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  static bool _useHeadBlock(List<CalendarEntry> ordered, CalendarEntry selected) {
    if (ordered.length < 2) return false;
    final ix = ordered.indexWhere((e) => e.id == selected.id);
    return ix == 0;
  }

  static bool _useTailBlock(List<CalendarEntry> ordered, CalendarEntry selected) {
    if (ordered.length < 2) return false;
    final ix = ordered.indexWhere((e) => e.id == selected.id);
    return ix == ordered.length - 1;
  }

  /// Anzahl Karten im Kopf-/Schwanz-Block (max. 3, min. 2 wenn n≥2).
  static int _mergedEndCount(int n) {
    if (n < 2) return 0;
    return n >= 3 ? 3 : 2;
  }

  static int _headMergeCount(List<CalendarEntry> ordered, CalendarEntry selected) {
    return _useHeadBlock(ordered, selected) ? _mergedEndCount(ordered.length) : 0;
  }

  static int _tailMergeCount(List<CalendarEntry> ordered, CalendarEntry selected) {
    return _useTailBlock(ordered, selected) ? _mergedEndCount(ordered.length) : 0;
  }

  Widget _entryCard(CalendarEntry e) {
    return _HeaderEntryCard(
      entry: e,
      applyPastStyling: widget.applyPastStyling,
      isSelected: e.id == widget.selected.id,
    );
  }

  void _scheduleCenterSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _selectedKey.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.5,
        duration: Duration.zero,
        curve: Curves.linear,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final ordered = _ordered(widget);
    final pad =
        (widget.viewportHeight > 0 ? widget.viewportHeight : 0) * 0.25;
    final listStartsWithFirstOfDay = widget.firstEntryOfDay != null &&
        ordered.isNotEmpty &&
        ordered.first.id == widget.firstEntryOfDay!.id;
    final topPad = pad +
        (listStartsWithFirstOfDay ? _kFirstOfDayModalListExtraTop : 0);
    final n = ordered.length;
    final kHead = _headMergeCount(ordered, widget.selected);
    final kTail = _tailMergeCount(ordered, widget.selected);
    final itemCount = kTail > 0
        ? n - kTail + 1
        : kHead > 0
            ? n - kHead + 1
            : n;

    final fadeInStop = widget.hasNeighborBefore
        ? _kModalListEdgeFadeIn
        : _kModalListEdgeFadeShortIn;
    final fadeOutStop = widget.hasNeighborAfter
        ? _kModalListEdgeFadeOut
        : _kModalListEdgeFadeShortOut;

    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0x00FFFFFF),
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
            Color(0x00FFFFFF),
          ],
          stops: [0, fadeInStop, fadeOutStop, 1],
        ).createShader(bounds);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
        child: ListView.separated(
          // Nur programmatisch über [ensureVisible] — kein Wisch-Konflikt mit dem Sheet.
          physics: const NeverScrollableScrollPhysics(),
          clipBehavior: Clip.hardEdge,
          padding: EdgeInsets.fromLTRB(0, topPad, 0, pad),
          itemCount: itemCount,
          separatorBuilder: (_, _) => const SizedBox(height: _kModalCardSpacing),
          itemBuilder: (context, index) {
            Widget wrapSelected(CalendarEntry e, Widget card) {
              if (e.id == widget.selected.id) {
                return KeyedSubtree(key: _selectedKey, child: card);
              }
              return card;
            }

            if (kHead > 0 && index == 0) {
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < kHead; i++) ...[
                      if (i > 0) const SizedBox(height: _kModalCardSpacing),
                      wrapSelected(ordered[i], _entryCard(ordered[i])),
                    ],
                  ],
                ),
              );
            }
            if (kTail > 0 && index == itemCount - 1) {
              final start = n - kTail;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < kTail; i++) ...[
                    if (i > 0) const SizedBox(height: _kModalCardSpacing),
                    wrapSelected(
                      ordered[start + i],
                      _entryCard(ordered[start + i]),
                    ),
                  ],
                ],
              );
            }

            final oi = kHead > 0 ? kHead + index - 1 : index;
            final e = ordered[oi];
            return wrapSelected(e, _entryCard(e));
          },
        ),
      ),
    );
  }
}

class _HeaderEntryCard extends StatelessWidget {
  final CalendarEntry entry;
  final bool applyPastStyling;
  final bool isSelected;

  const _HeaderEntryCard({
    required this.entry,
    required this.applyPastStyling,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = CalendarEntryCard(
      entry: entry,
      applyPastStyling: applyPastStyling,
      listTileHorizontalPadding: 0,
      cardContentPadding: _kModalPreviewCardPadding,
      cardTitleFontSize: _kModalPreviewTitleFontSize,
    );

    if (!isSelected) {
      card = ColorFiltered(
        colorFilter: _kGrayscale,
        child: Opacity(
          opacity: _kMutedCardOpacity,
          child: card,
        ),
      );
    }

    return IgnorePointer(
      child: SizedBox(
        width: double.infinity,
        child: card,
      ),
    );
  }
}
