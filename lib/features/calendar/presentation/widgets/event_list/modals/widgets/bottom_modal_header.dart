import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_accent_overrides_provider.dart';
import 'package:chronoapp/features/calendar/presentation/providers/filter/calendar/calendar_filtered_entries_providers.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/calendar_entry_card.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/event_list.dart'
    show kBottomModalHeaderHeight;
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/modal_preview_card_chrome.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Max. Blur (σ) — gilt erst bei größerem Abstand zur Auswahl.
const double kModalPreviewNeighborBlurSigmaMax = 5;

/// Min. Blur direkt neben der Auswahl (soll noch lesbar bleiben).
const double kModalPreviewNeighborBlurSigmaMin = 0.8;

/// Abstand ≥ dieses Ziel → volle Blur-Stärke ([kModalPreviewNeighborBlurSigmaMax]).
const double kModalPreviewBlurDistanceNorm = 3;

/// > 1: Blur/Farbe wachsen am Anfang langsamer (exponentielle Kurve).
const double kModalPreviewBlurCurveExponent = 2.4;

/// Glas-Tönung: Minimum (Abstand 1) und Maximum (ferne Nachbarn).
const double kModalPreviewNeighborGlassTintMin = 0.045;
const double kModalPreviewNeighborGlassTintMax = 0.15;

/// Farbe wächst schneller als Blur (niedrigerer Exponent = mehr Farbe früh).
const double kModalPreviewTintCurveExponent = 1.2;

/// σ für Nachbar-Karten: exponentiell nach Abstand zur Auswahl.
double modalPreviewBlurSigmaForDistance(int distanceFromSelected) {
  if (distanceFromSelected <= 0) return 0;
  final t = (distanceFromSelected / kModalPreviewBlurDistanceNorm)
      .clamp(0.0, 1.0);
  final curved = math.pow(t, kModalPreviewBlurCurveExponent).toDouble();
  return kModalPreviewNeighborBlurSigmaMin +
      (kModalPreviewNeighborBlurSigmaMax - kModalPreviewNeighborBlurSigmaMin) *
          curved;
}

/// Glas-Tönung: stärker und früher als der Blur.
double modalPreviewGlassTintForDistance(int distanceFromSelected) {
  if (distanceFromSelected <= 0) return 0;
  final t = (distanceFromSelected / kModalPreviewBlurDistanceNorm)
      .clamp(0.0, 1.0);
  final curved = math.pow(t, kModalPreviewTintCurveExponent).toDouble();
  return kModalPreviewNeighborGlassTintMin +
      (kModalPreviewNeighborGlassTintMax - kModalPreviewNeighborGlassTintMin) *
          curved;
}

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

/// Vertikaler Masken-Verlauf ([ShaderMask]): Mitte = volle Sicht (breiter).
const double _kModalListEdgeFadeIn = 0.32;
const double _kModalListEdgeFadeOut = 0.68;

/// Wenn oberhalb / unterhalb des ausgewählten Eintrags keine weiteren Karten
/// in der Vorschau sind: kürzere Ausblendzone an dieser Kante (Termin „beginnt“
/// bzw. „endet“ dort).
const double _kModalListEdgeFadeShortIn = 0.10;
const double _kModalListEdgeFadeShortOut = 0.80;

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
    this.morph = 0,
  });

  /// Wenn false, übernimmt ein äußeres [ClipRRect] (z. B. [BaseBottomModal]) die oberen Ecken.
  final bool clipTopCorners;

  /// 0 = Detail-Liste, 1 = zentrierte Akzent-Vorschau (siehe [BottomModalHeaderMorph]).
  final double morph;

  static DateTime _localDayStart(CalendarEntry anchor) {
    final local = anchor.startTime.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static List<CalendarEntry> _entriesOnLocalDay(
    List<CalendarEntry> dayEntries,
    DateTime dayStart,
  ) {
    final y = dayStart.year;
    final m = dayStart.month;
    final d = dayStart.day;
    final sameDay = dayEntries.where((e) {
      final s = e.startTime.toLocal();
      return s.year == y && s.month == m && s.day == d;
    }).toList();
    sameDay.sort((a, b) => a.startTime.compareTo(b.startTime));
    return sameDay;
  }

  static CalendarEntry? _firstEntryOfLocalDay(
    List<CalendarEntry> dayEntries,
    DateTime dayStart,
  ) {
    final sameDay = _entriesOnLocalDay(dayEntries, dayStart);
    return sameDay.isEmpty ? null : sameDay.first;
  }

  /// Chronologisch unmittelbar vor [anchor] am selben lokalen Tag.
  static CalendarEntry? _entryImmediatelyBeforeOnDay(
    List<CalendarEntry> daySorted,
    CalendarEntry anchor,
  ) {
    final ix = daySorted.indexWhere((e) => e.id == anchor.id);
    if (ix <= 0) return null;
    return daySorted[ix - 1];
  }

  /// Chronologisch unmittelbar nach [anchor] am selben lokalen Tag.
  static CalendarEntry? _entryImmediatelyAfterOnDay(
    List<CalendarEntry> daySorted,
    CalendarEntry anchor,
  ) {
    final ix = daySorted.indexWhere((e) => e.id == anchor.id);
    if (ix < 0 || ix >= daySorted.length - 1) return null;
    return daySorted[ix + 1];
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
                      top: Radius.circular(AppRadius.sheet),
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
                  final daySorted = _entriesOnLocalDay(dayEntries, dayStart);
                  final h = displayEntry.startTime.toLocal().hour;

                  var curr = _entriesStartingAtLocalHour(
                    dayEntries,
                    dayStart,
                    h,
                  );
                  if (curr.isEmpty) {
                    curr = [displayEntry];
                  }
                  var prev = _entriesStartingAtLocalHour(
                    dayEntries,
                    dayStart,
                    h - 1,
                  );
                  var next = _entriesStartingAtLocalHour(
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

                  // Lücken zwischen Stunden: letzten / nächsten Termin des Tages
                  // als Vorschau, damit oben/unten nicht leer wirkt.
                  if (prev.isEmpty) {
                    final before = _entryImmediatelyBeforeOnDay(
                      daySorted,
                      displayEntry,
                    );
                    if (before != null &&
                        !beforeSel.any((e) => e.id == before.id)) {
                      prev = [before];
                    }
                  }
                  if (next.isEmpty) {
                    final after = _entryImmediatelyAfterOnDay(
                      daySorted,
                      displayEntry,
                    );
                    if (after != null &&
                        !afterSel.any((e) => e.id == after.id)) {
                      next = [after];
                    }
                  }
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
                    morph: morph,
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
                top: Radius.circular(AppRadius.sheet),
              ),
              clipBehavior: Clip.hardEdge,
              child: stack,
            )
          : stack,
    );
  }
}

/// Morph zwischen Detail-Ansicht und zentrierter Akzent-Vorschau.
///
/// Nutzt dieselbe Liste wie [BottomModalHeader] (identische Geometrie, kein
/// Layout-Sprung). Mit steigendem [morph] fliegen die Nachbar-Karten nach
/// oben/unten weg und die Uhrzeit-Spalte des ausgewählten Termins klappt ein —
/// der ausgewählte Termin bleibt dabei exakt zentriert.
class BottomModalHeaderMorph extends StatelessWidget {
  const BottomModalHeaderMorph({
    super.key,
    required this.entry,
    required this.morph,
    this.height = kBottomModalHeaderHeight,
    this.clipTopCorners = false,
  });

  final CalendarEntry entry;
  final Animation<double> morph;
  final double height;
  final bool clipTopCorners;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: morph,
      builder: (context, _) {
        return BottomModalHeader(
          entry: entry,
          height: height,
          clipTopCorners: clipTopCorners,
          morph: morph.value.clamp(0.0, 1.0),
        );
      },
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
                      top: Radius.circular(AppRadius.sheet),
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
                top: Radius.circular(AppRadius.sheet),
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
                      top: Radius.circular(AppRadius.sheet),
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
                top: Radius.circular(AppRadius.sheet),
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
class _PreviewCardFrame extends ConsumerWidget {
  const _PreviewCardFrame({required this.entry});

  final CalendarEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final headerAccent = resolveCalendarEntryAccent(ref, entry);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      child: IgnorePointer(
        child: ModalPreviewCardChrome(
          entry: entry,
          headerAccentColor: headerAccent,
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

  /// 0 = Detail, 1 = Akzent-Vorschau. Treibt das In-Place-Morph.
  final double morph;

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
    this.morph = 0,
  });

  @override
  State<_ModalHeaderEntryList> createState() => _ModalHeaderEntryListState();
}

class _ModalHeaderEntryListState extends State<_ModalHeaderEntryList> {
  final GlobalKey _selectedKey = GlobalKey();

  /// Höhe der Auswahl-Karte bei morph=0 — verhindert vertikales „Wachsen“ beim Morph.
  double? _selectedCardHeight;

  @override
  void initState() {
    super.initState();
    _scheduleCenterSelected();
    _scheduleMeasureSelectedHeight();
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
      _selectedCardHeight = null;
      _scheduleCenterSelected();
      _scheduleMeasureSelectedHeight();
    } else if (widget.morph <= 0 && oldWidget.morph > 0) {
      _selectedCardHeight = null;
      _scheduleMeasureSelectedHeight();
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

  int _distanceFromSelected(CalendarEntry e, List<CalendarEntry> ordered) {
    final selIx = ordered.indexWhere((x) => x.id == widget.selected.id);
    final ix = ordered.indexWhere((x) => x.id == e.id);
    if (selIx < 0 || ix < 0) return 1;
    return (ix - selIx).abs();
  }

  Widget _entrySlot(CalendarEntry e, List<CalendarEntry> ordered) {
    final isSelected = e.id == widget.selected.id;
    final distance = _distanceFromSelected(e, ordered);
    final m = widget.morph.clamp(0.0, 1.0);

    if (isSelected) {
      // Uhrzeit-Spalte klappt horizontal ein; Höhe bleibt fix (kein Wachstum nach unten).
      final collapse = (1 - Curves.easeInOut.transform(m)).clamp(0.0, 1.0);
      Widget card = _HeaderEntryCard(
        entry: e,
        applyPastStyling: widget.applyPastStyling,
        modalHeaderPreview: true,
        timeColumnCollapse: collapse,
      );
      final lockedH = _selectedCardHeight;
      if (lockedH != null && m > 0) {
        card = SizedBox(
          height: lockedH,
          child: Align(alignment: Alignment.center, child: card),
        );
      }
      return KeyedSubtree(key: _selectedKey, child: card);
    }

    final card = _HeaderEntryCard(
      entry: e,
      applyPastStyling: widget.applyPastStyling,
      modalHeaderPreview: true,
      neighborGlassBlurSigma: modalPreviewBlurSigmaForDistance(distance),
      neighborGlassTintAlpha: modalPreviewGlassTintForDistance(distance),
    );

    if (m <= 0) return card;

    // Nachbarn fliegen weg (oben/unten) und blenden aus — ohne den Layout-Platz
    // zu verändern, damit der ausgewählte Termin exakt zentriert bleibt.
    final selIx = ordered.indexWhere((x) => x.id == widget.selected.id);
    final ix = ordered.indexWhere((x) => x.id == e.id);
    final above = ix < selIx;
    final fly = Curves.easeInCubic.transform(m);
    final dy = (above ? -1.0 : 1.0) * widget.viewportHeight * 0.6 * fly;
    final opacity = (1 - Curves.easeOutCubic.transform(m)).clamp(0.0, 1.0);

    return Opacity(
      opacity: opacity,
      child: Transform.translate(offset: Offset(0, dy), child: card),
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

  void _scheduleMeasureSelectedHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.morph > 0.01) return;
      final box = _selectedKey.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return;
      final h = box.size.height;
      if (_selectedCardHeight != h) {
        setState(() => _selectedCardHeight = h);
      }
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
        // Exponentielle Ein-/Ausblendung: in der Mitte länger volle Sicht.
        final fadeIn = math.pow(fadeInStop, 1.35).toDouble();
        final fadeOut = 1 - math.pow(1 - fadeOutStop, 1.35).toDouble();
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0x00FFFFFF),
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
            Color(0x00FFFFFF),
          ],
          stops: [0, fadeIn, fadeOut, 1],
        ).createShader(bounds);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
        child: ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          clipBehavior: Clip.hardEdge,
          padding: EdgeInsets.fromLTRB(0, topPad, 0, pad),
          itemCount: itemCount,
          separatorBuilder: (_, _) =>
              const SizedBox(height: _kModalCardSpacing),
          itemBuilder: (context, index) {
            if (kHead > 0 && index == 0) {
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < kHead; i++) ...[
                      if (i > 0) const SizedBox(height: _kModalCardSpacing),
                      _entrySlot(ordered[i], ordered),
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
                    _entrySlot(ordered[start + i], ordered),
                  ],
                ],
              );
            }

            final oi = kHead > 0 ? kHead + index - 1 : index;
            return _entrySlot(ordered[oi], ordered);
          },
        ),
      ),
    );
  }
}

class _HeaderEntryCard extends ConsumerWidget {
  final CalendarEntry entry;
  final bool applyPastStyling;
  final bool modalHeaderPreview;
  final double timeColumnCollapse;
  final double? neighborGlassBlurSigma;
  final double? neighborGlassTintAlpha;

  const _HeaderEntryCard({
    required this.entry,
    required this.applyPastStyling,
    this.modalHeaderPreview = false,
    this.timeColumnCollapse = 1,
    this.neighborGlassBlurSigma,
    this.neighborGlassTintAlpha,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (modalHeaderPreview && timeColumnCollapse >= 0.99) {
      return IgnorePointer(
        child: ModalPreviewHeaderEntryRow(
          entry: entry,
          headerAccentColor: resolveCalendarEntryAccent(ref, entry),
          applyPastStyling: applyPastStyling,
          neighborGlassBlurSigma: neighborGlassBlurSigma,
          neighborGlassTintAlpha: neighborGlassTintAlpha,
        ),
      );
    }

    return IgnorePointer(
      child: SizedBox(
        width: double.infinity,
        child: CalendarEntryCard(
          entry: entry,
          applyPastStyling: applyPastStyling,
          listTileHorizontalPadding:
              modalHeaderPreview ? AppSpacing.s : 0,
          cardContentPadding: _kModalPreviewCardPadding,
          cardTitleFontSize: _kModalPreviewTitleFontSize,
          modalHeaderPreview: modalHeaderPreview,
          timeColumnCollapse: timeColumnCollapse,
          neighborGlassBlurSigma: neighborGlassBlurSigma,
          neighborGlassTintAlpha: neighborGlassTintAlpha,
        ),
      ),
    );
  }
}
