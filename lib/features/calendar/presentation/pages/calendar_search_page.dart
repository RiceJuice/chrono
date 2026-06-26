import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../../core/theme/theme_tokens.dart';
import '../../../../core/time/app_date_time.dart';
import '../../domain/models/calendar_entry.dart';
import '../providers/calendar_providers.dart';
import '../widgets/event_list/cards/calendar_entry_card.dart';
import '../widgets/search_results/calendar_day_section_header.dart';
import '../widgets/search_results/search_results_sections.dart';

class CalendarSearchPage extends ConsumerStatefulWidget {
  const CalendarSearchPage({
    required this.query,
    this.playInitialMorph = false,
    super.key,
  });

  final String query;
  final bool playInitialMorph;

  @override
  ConsumerState<CalendarSearchPage> createState() => _CalendarSearchPageState();
}

class _CalendarSearchPageState extends ConsumerState<CalendarSearchPage> {
  static const double _stickyHeaderHeight = 40;
  static const Duration _initialMorphWindow = Duration(milliseconds: 520);

  double get _listTopPadding => _stickyHeaderHeight;

  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  DateTime? _stickyDay;
  double _stickyHeaderPushOffset = 0;
  double _listViewportHeight = 0;
  List<_SearchListRow> _rowsForSticky = const <_SearchListRow>[];
  bool _hasUserInteractedWithList = false;
  bool _playInitialMorph = false;
  Timer? _initialMorphTimer;

  @override
  void initState() {
    super.initState();
    _playInitialMorph = widget.playInitialMorph;
    _scheduleInitialMorphEnd();
    _itemPositionsListener.itemPositions.addListener(
      _updateStickyDayFromPositions,
    );
  }

  @override
  void didUpdateWidget(covariant CalendarSearchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _stickyDay = null;
      _stickyHeaderPushOffset = 0;
      _hasUserInteractedWithList = false;
    }
    if (!oldWidget.playInitialMorph && widget.playInitialMorph) {
      _restartInitialMorph();
    }
  }

  @override
  void dispose() {
    _initialMorphTimer?.cancel();
    _itemPositionsListener.itemPositions.removeListener(
      _updateStickyDayFromPositions,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(searchFiltersProvider);
    final entriesAsync = ref.watch(
      filteredCalendarEntriesByQueryProvider(widget.query),
    );

    return entriesAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => _dismissSearchKeyboard(),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search,
                    size: 60,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  Text(
                    'Keine Treffer gefunden',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'Überprüfe deine Eingabe oder versuche es mit anderen Suchbegriffen.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final sectionsResult = buildSearchResultsSections(entries: entries);
        final rows = _buildRows(sectionsResult.sections);
        _rowsForSticky = rows;
        final targetRowIndex = _firstRowIndexForSection(
          rows: rows,
          sectionIndex: sectionsResult.initialSectionIndex,
        );

        final theme = Theme.of(context);
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _dismissSearchKeyboard(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              
              Expanded(
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        _listViewportHeight = constraints.maxHeight;
                        return ColoredBox(
                          color: theme.scaffoldBackgroundColor,
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (notification is ScrollStartNotification ||
                                  notification is ScrollUpdateNotification ||
                                  notification is UserScrollNotification) {
                                _dismissSearchKeyboard();
                              }
                              if (_hasUserInteractedWithList) return false;
                              if (notification is ScrollUpdateNotification &&
                                  notification.dragDetails != null) {
                                _hasUserInteractedWithList = true;
                              } else if (notification is UserScrollNotification &&
                                  notification.direction !=
                                      ScrollDirection.idle) {
                                _hasUserInteractedWithList = true;
                              }
                              return false;
                            },
                            child: ScrollablePositionedList.builder(
                              key: ValueKey(
                                'search-list-${widget.query}-${_filtersSignature(filters)}',
                              ),
                              itemPositionsListener: _itemPositionsListener,
                              padding: EdgeInsets.only(
                                top: _listTopPadding,
                                bottom: AppSpacing.l,
                              ),
                              itemCount: rows.length,
                              initialScrollIndex: targetRowIndex,
                              itemBuilder: (context, index) {
                                final row = rows[index];
                                final lastIndex = rows.length - 1;
                                final Widget child;
                                if (row.headerDay != null) {
                                  child = CalendarDaySectionHeader(
                                    day: row.headerDay!,
                                    height: _stickyHeaderHeight,
                                  );
                                } else {
                                  child = CalendarEntryCard(
                                    key: ValueKey<String>(
                                      'calendar-entry-${row.entry!.id}',
                                    ),
                                    entry: row.entry!,
                                    applyPastStyling: true,
                                  );
                                }
                                final morphedChild = _wrapInitialMorph(
                                  child: child,
                                  index: index,
                                );
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    morphedChild,
                                    if (index != lastIndex)
                                      const SizedBox(height: AppSpacing.m),
                                  ],
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    if (_stickyDay != null &&
                        _stickyHeaderPushOffset > -_stickyHeaderHeight)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          child: Transform.translate(
                            offset: Offset(0, _stickyHeaderPushOffset),
                            child: CalendarDaySectionHeader(
                              day: _stickyDay!,
                              height: _stickyHeaderHeight,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () {
        _stickyDay = null;
        _stickyHeaderPushOffset = 0;
        return const _DebouncedLoadingIndicator();
      },
      error: (err, stack) => Center(child: Text('Fehler: $err')),
    );
  }

  void _restartInitialMorph() {
    _initialMorphTimer?.cancel();
    setState(() {
      _playInitialMorph = true;
    });
    _scheduleInitialMorphEnd();
  }

  void _scheduleInitialMorphEnd() {
    if (!_playInitialMorph) return;
    _initialMorphTimer = Timer(_initialMorphWindow, () {
      if (!mounted) return;
      setState(() {
        _playInitialMorph = false;
      });
    });
  }

  Widget _wrapInitialMorph({required Widget child, required int index}) {
    if (!_playInitialMorph) return child;

    final cappedIndex = index.clamp(0, 8);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutExpo,
      builder: (context, value, child) {
        final start = (0.038 * cappedIndex).clamp(0.0, 0.32);
        final effectiveValue = ((value - start) / (1 - start)).clamp(0.0, 1.0);
        final eased = Curves.easeOutCubic.transform(effectiveValue);
        final settleValue = Curves.easeOut.transform(
          ((effectiveValue - 0.78) / 0.22).clamp(0.0, 1.0),
        );
        final scale = 0.965 + (0.039 * eased) - (0.004 * settleValue);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, (1 - eased) * 18),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }

  void _dismissSearchKeyboard() {
    final inputFocus = ref.read(calendarSearchInputFocusedProvider);
    if (!inputFocus) return;
    FocusManager.instance.primaryFocus?.unfocus();
    ref.read(calendarSearchInputFocusedProvider.notifier).dismiss();
  }

  List<_SearchListRow> _buildRows(List<SearchDaySection> sections) {
    final rows = <_SearchListRow>[];
    for (var sectionIndex = 0; sectionIndex < sections.length; sectionIndex++) {
      rows.add(
        _SearchListRow.header(
          sectionIndex: sectionIndex,
          day: sections[sectionIndex].day,
        ),
      );
      for (final entry in sections[sectionIndex].entries) {
        rows.add(
          _SearchListRow.entry(sectionIndex: sectionIndex, entry: entry),
        );
      }
    }
    return rows;
  }

  int _firstRowIndexForSection({
    required List<_SearchListRow> rows,
    required int sectionIndex,
  }) {
    for (var i = 0; i < rows.length; i++) {
      if (rows[i].sectionIndex == sectionIndex && rows[i].headerDay != null) {
        return i;
      }
    }
    return 0;
  }

  void _updateStickyDayFromPositions() {
    if (!mounted || _rowsForSticky.isEmpty) return;
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final visible = positions
        .where((p) => p.itemTrailingEdge > 0 && p.itemLeadingEdge < 1)
        .toList();
    if (visible.isEmpty) return;

    visible.sort((a, b) => a.index.compareTo(b.index));

    int? contentTopIndex;
    for (final v in visible) {
      if (v.index >= _rowsForSticky.length) continue;
      contentTopIndex = v.index;
      break;
    }

    DateTime? nextStickyDay;
    var pushOffset = 0.0;

    if (contentTopIndex != null) {
      final topIndex = contentTopIndex;
      nextStickyDay = _rowsForSticky[topIndex].headerDay;
      if (nextStickyDay == null) {
        for (var i = topIndex; i >= 0; i--) {
          final candidate = _rowsForSticky[i].headerDay;
          if (candidate != null) {
            nextStickyDay = candidate;
            break;
          }
        }
      }

      if (_listViewportHeight > 0 && nextStickyDay != null) {
        final nextHeaderPosition =
            visible
                .where(
                  (p) =>
                      p.index > topIndex &&
                      _rowsForSticky[p.index].headerDay != null,
                )
                .toList()
              ..sort((a, b) => a.index.compareTo(b.index));
        if (nextHeaderPosition.isNotEmpty) {
          final leadingPx =
              nextHeaderPosition.first.itemLeadingEdge * _listViewportHeight;
          if (leadingPx < _stickyHeaderHeight) {
            pushOffset = leadingPx - _stickyHeaderHeight;
          }
        }

        if (pushOffset <= -_stickyHeaderHeight) {
          nextStickyDay = null;
          pushOffset = 0;
        }
      }
    }

    final stickyDayChanged =
        (_stickyDay == null) != (nextStickyDay == null) ||
        (nextStickyDay != null &&
            _stickyDay != null &&
            !_isSameDay(_stickyDay!, nextStickyDay));
    if (stickyDayChanged &&
        _hasUserInteractedWithList &&
        nextStickyDay != null) {
      HapticFeedback.mediumImpact();
    }

    if (stickyDayChanged ||
        (_stickyHeaderPushOffset - pushOffset).abs() > 0.1) {
      setState(() {
        _stickyDay = nextStickyDay;
        _stickyHeaderPushOffset = pushOffset;
      });
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return AppDateTime.isSameLocalDay(a, b);
  }

  String _filtersSignature(CalendarFiltersState filters) {
    return [
      ...filters.choirs,
      '::',
      ...filters.voices,
      '::',
      ...filters.classNames,
      '::',
      ...filters.schoolTracks,
    ].join('|');
  }
}

class _SearchListRow {
  const _SearchListRow._({
    required this.sectionIndex,
    this.headerDay,
    this.entry,
  });

  factory _SearchListRow.header({
    required int sectionIndex,
    required DateTime day,
  }) => _SearchListRow._(sectionIndex: sectionIndex, headerDay: day);

  factory _SearchListRow.entry({
    required int sectionIndex,
    required CalendarEntry entry,
  }) => _SearchListRow._(sectionIndex: sectionIndex, entry: entry);

  final int sectionIndex;
  final DateTime? headerDay;
  final CalendarEntry? entry;
}

class _DebouncedLoadingIndicator extends StatefulWidget {
  const _DebouncedLoadingIndicator();

  @override
  State<_DebouncedLoadingIndicator> createState() =>
      _DebouncedLoadingIndicatorState();
}

class _DebouncedLoadingIndicatorState
    extends State<_DebouncedLoadingIndicator> {
  static const Duration _delay = Duration(milliseconds: 220);
  bool _showSpinner = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(_delay, () {
      if (!mounted) return;
      setState(() {
        _showSpinner = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_showSpinner) {
      return const SizedBox.shrink();
    }
    return const Center(child: CircularProgressIndicator());
  }
}
