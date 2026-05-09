import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_accent_overrides_provider.dart';
import 'package:chronoapp/features/calendar/presentation/providers/filter/calendar/calendar_filtered_entries_providers.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/calendar_entry_card.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/event_list.dart'
    show kBottomModalHeaderHeight;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Graustufen (Luminanz) — alle nicht ausgewählten Karten gleich behandelt.
const ColorFilter _kGrayscale = ColorFilter.matrix(<double>[
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
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

class BottomModalHandle extends StatelessWidget {
  const BottomModalHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      ),
    );
  }
}

class BottomModalHeader extends ConsumerWidget {
  final CalendarEntry entry;
  final double height;

  const BottomModalHeader({
    super.key,
    required this.entry,
    this.height = kBottomModalHeaderHeight,
    this.clipTopCorners = false,
  });

  /// Wenn false, übernimmt ein äußeres [ClipRRect] (z. B. [BaseBottomModal]) die oberen Ecken.
  final bool clipTopCorners;

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
    final displayEntry = entry.copyWith(
      accentColor: resolveCalendarEntryAccent(ref, entry),
    );
    final day = AppDateTime.localDay(displayEntry.startTime);
    final entriesAsync = ref.watch(filteredCalendarEntriesForDayProvider(day));
    final headerH = height;

    final stack = Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: displayEntry.accentColor,
              borderRadius: clipTopCorners
                  ? const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.xl),
                    )
                  : null,
            ),
          ),
        ),
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return entriesAsync.when(
                data: (dayEntries) {
                  final dayStart = _localDayStart(displayEntry);
                  final h = displayEntry.startTime.toLocal().hour;

                  var curr = _entriesStartingAtLocalHour(
                    dayEntries,
                    dayStart,
                    h,
                  );
                  if (curr.isEmpty) {
                    curr = [displayEntry];
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

                  final selectedIdx = curr.indexWhere(
                    (e) => e.id == displayEntry.id,
                  );
                  final ix = selectedIdx >= 0 ? selectedIdx : 0;
                  final selected = curr[ix];
                  final beforeSel = curr.sublist(0, ix);
                  final afterSel = curr.sublist(ix + 1, curr.length);
                  final firstOfDay = _firstEntryOfLocalDay(
                    dayEntries,
                    dayStart,
                  );

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
                  final hasNeighborBefore = si > 0 && orderedPreview.isNotEmpty;
                  final hasNeighborAfter =
                      si >= 0 && si < orderedPreview.length - 1;

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
                    applyPastStyling: AppDateTime.isTodayLocal(
                      curr.first.startTime,
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              );
            },
          ),
        ),
        // Handle über der Liste, damit darunterliegende (gedimmte) Karten erlaubt sind.
        const BottomModalHandle(),
      ],
    );

    return SizedBox(
      height: headerH,
      child: clipTopCorners
          ? ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xl),
              ),
              clipBehavior: Clip.hardEdge,
              child: stack,
            )
          : stack,
    );
  }
}

/// Eine einzelne Karte, zentriert, ohne Uhrzeit — für Kalender-Einstellungen / Akzent-Vorschau.
class BottomModalHeaderPreview extends ConsumerWidget {
  final CalendarEntry entry;
  final double height;

  const BottomModalHeaderPreview({
    super.key,
    required this.entry,
    this.height = kBottomModalHeaderHeight,
    this.clipTopCorners = false,
  });

  /// Wenn false, sorgt das übergeordnete Sheet für eine einheitliche Rundung.
  final bool clipTopCorners;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayEntry = entry.copyWith(
      accentColor: resolveCalendarEntryAccent(ref, entry),
    );
    final stack = Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: displayEntry.accentColor,
              borderRadius: clipTopCorners
                  ? const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.xl),
                    )
                  : null,
            ),
          ),
        ),
        Center(
          child: _PreviewCardFrame(entry: displayEntry),
        ),
        const BottomModalHandle(),
      ],
    );

    return SizedBox(
      height: height,
      child: clipTopCorners
          ? ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xl),
              ),
              clipBehavior: Clip.hardEdge,
              child: stack,
            )
          : stack,
    );
  }
}

/// Mehrseitige Vorschau: Akzentfarbe füllt fest den Hintergrund und wird beim
/// Wischen sanft zwischen den Seiten interpoliert. Nur die Karte selbst sitzt
/// im [PageView] und scrollt mit.
class BottomModalHeaderPreviewSwiper extends StatelessWidget {
  const BottomModalHeaderPreviewSwiper({
    super.key,
    required this.entries,
    required this.pageController,
    required this.pageValue,
    required this.activeIndex,
    this.height = kBottomModalHeaderHeight,
    this.clipTopCorners = false,
    this.bgAnimationDuration = const Duration(milliseconds: 320),
  });

  /// Eine Karte pro Seite. Die [CalendarEntry.accentColor] der Einträge wird
  /// für die Hintergrundinterpolation benutzt — also vom Aufrufer bereits
  /// auflösen (z. B. via [resolveCalendarEntryAccent]).
  final List<CalendarEntry> entries;
  final PageController pageController;

  /// Aktuelle Position des [PageController]s als Gleitkommawert (0..n-1),
  /// genutzt für die Crossfade-Animation des Akzent-Hintergrunds.
  final double pageValue;
  final int activeIndex;
  final double height;
  final bool clipTopCorners;

  /// Sanfte Nachhilfe-Animation, falls sich die Akzentfarbe einer Seite ändert
  /// (z. B. im Color-Picker), während der [PageController] in Ruhe ist.
  final Duration bgAnimationDuration;

  @override
  Widget build(BuildContext context) {
    final hasMultiplePages = entries.length > 1;
    final bgColor = _interpolatedAccent(entries, pageValue);

    final stack = Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(
          child: AnimatedContainer(
            duration: bgAnimationDuration,
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: clipTopCorners
                  ? const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.xl),
                    )
                  : null,
            ),
          ),
        ),
        Positioned.fill(
          child: PageView.builder(
            controller: pageController,
            physics: hasMultiplePages
                ? const BouncingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              return Center(child: _PreviewCardFrame(entry: entries[index]));
            },
          ),
        ),
        const BottomModalHandle(),
        if (hasMultiplePages)
          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: _PreviewPageDots(
              count: entries.length,
              activeIndex: activeIndex,
            ),
          ),
      ],
    );

    return SizedBox(
      height: height,
      child: clipTopCorners
          ? ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xl),
              ),
              clipBehavior: Clip.hardEdge,
              child: stack,
            )
          : stack,
    );
  }

  /// Wechselt erst beim Überschreiten der 50%-Marke zwischen zwei Seiten auf
  /// die nächste Akzentfarbe. Den weichen Übergang übernimmt der äußere
  /// [AnimatedContainer] – so passiert die Animation tatsächlich erst nach der
  /// Hälfte des Wisches und nicht kontinuierlich von Anfang an.
  Color _interpolatedAccent(List<CalendarEntry> entries, double page) {
    if (entries.isEmpty) return Colors.transparent;
    final idx = page.round().clamp(0, entries.length - 1);
    return entries[idx].accentColor;
  }
}

/// Visuelles Karten-Frame inkl. Schatten — gemeinsam genutzt von
/// [BottomModalHeaderPreview] und [BottomModalHeaderPreviewSwiper].
class _PreviewCardFrame extends StatelessWidget {
  const _PreviewCardFrame({required this.entry});

  final CalendarEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      child: IgnorePointer(
        child: Transform.scale(
          scale: 1.02,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.s),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: entry.accentColor.withValues(alpha: 0.5),
                  blurRadius: 28,
                  spreadRadius: -4,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CalendarEntryCard(
              entry: entry,
              applyPastStyling: false,
              showTimeColumn: false,
              showInlineTimeRange: false,
              listTileHorizontalPadding: 0,
              cardContentPadding: _kModalPreviewCardPadding,
              cardTitleFontSize: _kModalPreviewTitleFontSize,
            ),
          ),
        ),
      ),
    );
  }
}

/// Pillen-Indikator für die aktuell sichtbare Seite des Akzent-Vorschau-Swipers.
class _PreviewPageDots extends StatelessWidget {
  const _PreviewPageDots({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: i == activeIndex ? 22 : 8,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: i == activeIndex ? 0.95 : 0.55,
              ),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
      ],
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

  static bool _useHeadBlock(
    List<CalendarEntry> ordered,
    CalendarEntry selected,
  ) {
    if (ordered.length < 2) return false;
    final ix = ordered.indexWhere((e) => e.id == selected.id);
    return ix == 0;
  }

  static bool _useTailBlock(
    List<CalendarEntry> ordered,
    CalendarEntry selected,
  ) {
    if (ordered.length < 2) return false;
    final ix = ordered.indexWhere((e) => e.id == selected.id);
    return ix == ordered.length - 1;
  }

  /// Anzahl Karten im Kopf-/Schwanz-Block (max. 3, min. 2 wenn n≥2).
  static int _mergedEndCount(int n) {
    if (n < 2) return 0;
    return n >= 3 ? 3 : 2;
  }

  static int _headMergeCount(
    List<CalendarEntry> ordered,
    CalendarEntry selected,
  ) {
    return _useHeadBlock(ordered, selected)
        ? _mergedEndCount(ordered.length)
        : 0;
  }

  static int _tailMergeCount(
    List<CalendarEntry> ordered,
    CalendarEntry selected,
  ) {
    return _useTailBlock(ordered, selected)
        ? _mergedEndCount(ordered.length)
        : 0;
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
    final pad = (widget.viewportHeight > 0 ? widget.viewportHeight : 0) * 0.25;
    final listStartsWithFirstOfDay =
        widget.firstEntryOfDay != null &&
        ordered.isNotEmpty &&
        ordered.first.id == widget.firstEntryOfDay!.id;
    final topPad =
        pad + (listStartsWithFirstOfDay ? _kFirstOfDayModalListExtraTop : 0);
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
          separatorBuilder: (_, _) =>
              const SizedBox(height: _kModalCardSpacing),
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
        child: Opacity(opacity: _kMutedCardOpacity, child: card),
      );
    }

    return IgnorePointer(
      child: SizedBox(width: double.infinity, child: card),
    );
  }
}
