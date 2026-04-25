import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../domain/models/calendar_entry.dart';
import '../providers/calendar_providers.dart';
import '../theme/calendar_presentation_theme.dart';
import '../widgets/event_list/cards/calendar_entry_card.dart';
import '../widgets/search_results/search_results_sections.dart';

class CalendarSearchPage extends ConsumerStatefulWidget {
  const CalendarSearchPage({required this.query, super.key});

  final String query;

  @override
  ConsumerState<CalendarSearchPage> createState() => _CalendarSearchPageState();
}

class _CalendarSearchPageState extends ConsumerState<CalendarSearchPage> {
  static const double _stickyHeaderHeight = 40;
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  DateTime? _stickyDay;
  double _stickyHeaderPushOffset = 0;
  double _listViewportHeight = 0;
  List<_SearchListRow> _rowsForSticky = const <_SearchListRow>[];
  bool _hasUserInteractedWithList = false;

  @override
  void initState() {
    super.initState();
    _itemPositionsListener.itemPositions.addListener(_updateStickyDayFromPositions);
  }

  @override
  void didUpdateWidget(covariant CalendarSearchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _stickyDay = null;
      _stickyHeaderPushOffset = 0;
      _hasUserInteractedWithList = false;
    }
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_updateStickyDayFromPositions);
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.search,
                  size: 60,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
          );
        }

        final sectionsResult = buildSearchResultsSections(entries: entries);
        final rows = _buildRows(sectionsResult.sections);
        _rowsForSticky = rows;
        final targetRowIndex = _firstRowIndexForSection(
          rows: rows,
          sectionIndex: sectionsResult.initialSectionIndex,
        );

        return Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                _listViewportHeight = constraints.maxHeight;
                return NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (_hasUserInteractedWithList) return false;
                    if (notification is ScrollUpdateNotification &&
                        notification.dragDetails != null) {
                      _hasUserInteractedWithList = true;
                    } else if (notification is UserScrollNotification &&
                        notification.direction != ScrollDirection.idle) {
                      _hasUserInteractedWithList = true;
                    }
                    return false;
                  },
                  child: ScrollablePositionedList.builder(
                    key: ValueKey(
                      'search-list-${widget.query}-${_filtersSignature(filters)}',
                    ),
                    itemPositionsListener: _itemPositionsListener,
                    padding: const EdgeInsets.only(top: _stickyHeaderHeight),
                    itemCount: rows.length,
                    initialScrollIndex: targetRowIndex,
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      if (row.headerDay != null) {
                        return _buildDayHeader(context: context, day: row.headerDay!);
                      }
                      return CalendarEntryCard(
                        entry: row.entry!,
                        applyPastStyling: true,
                      );
                    },
                  ),
                );
              },
            ),
            if (_stickyDay != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Transform.translate(
                    offset: Offset(0, _stickyHeaderPushOffset),
                    child: _buildDayHeader(context: context, day: _stickyDay!),
                  ),
                ),
              ),
          ],
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

  bool _isToday(DateTime day) {
    final local = day.toLocal();
    final now = DateTime.now();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }

  bool _isPastDay(DateTime day) {
    final local = day.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayOnly = DateTime(local.year, local.month, local.day);
    return dayOnly.isBefore(today);
  }

  Widget _buildDayHeader({
    required BuildContext context,
    required DateTime day,
  }) {
    final baseStyle = Theme.of(context).textTheme.titleMedium;
    final isToday = _isToday(day);
    final isPastDay = _isPastDay(day);
    final style = isToday
        ? CalendarPresentationTheme.todayHeaderTextStyle(context, baseStyle)
        : isPastDay
            ? CalendarPresentationTheme.pastHeaderTextStyle(context, baseStyle)
            : baseStyle;

    return Container(
      height: _stickyHeaderHeight,
      color: Theme.of(context).scaffoldBackgroundColor,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        DateFormat('EEEE, d. MMMM', 'de').format(day),
        style: style?.copyWith(fontSize: 16),
      ),
    );
  }

  List<_SearchListRow> _buildRows(List<SearchDaySection> sections) {
    final rows = <_SearchListRow>[];
    for (var sectionIndex = 0; sectionIndex < sections.length; sectionIndex++) {
      rows.add(_SearchListRow.header(sectionIndex: sectionIndex, day: sections[sectionIndex].day));
      for (final entry in sections[sectionIndex].entries) {
        rows.add(_SearchListRow.entry(sectionIndex: sectionIndex, entry: entry));
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
    final topIndex = visible.first.index;

    DateTime? nextStickyDay = _rowsForSticky[topIndex].headerDay;
    if (nextStickyDay == null) {
      for (var i = topIndex; i >= 0; i--) {
        final candidate = _rowsForSticky[i].headerDay;
        if (candidate != null) {
          nextStickyDay = candidate;
          break;
        }
      }
    }

    if (nextStickyDay == null) return;
    var pushOffset = 0.0;
    if (_listViewportHeight > 0) {
      final nextHeaderPosition = visible
          .where((p) => p.index > topIndex && _rowsForSticky[p.index].headerDay != null)
          .toList()
        ..sort((a, b) => a.index.compareTo(b.index));
      if (nextHeaderPosition.isNotEmpty) {
        final leadingPx = nextHeaderPosition.first.itemLeadingEdge * _listViewportHeight;
        if (leadingPx < _stickyHeaderHeight) {
          pushOffset = leadingPx - _stickyHeaderHeight;
        }
      }
    }

    final stickyDayChanged = _stickyDay == null || !_isSameDay(_stickyDay!, nextStickyDay);
    if (stickyDayChanged && _hasUserInteractedWithList) {
      HapticFeedback.mediumImpact();
    }

    if (stickyDayChanged || (_stickyHeaderPushOffset - pushOffset).abs() > 0.1) {
      setState(() {
        _stickyDay = nextStickyDay;
        _stickyHeaderPushOffset = pushOffset;
      });
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    final aLocal = a.toLocal();
    final bLocal = b.toLocal();
    return aLocal.year == bLocal.year &&
        aLocal.month == bLocal.month &&
        aLocal.day == bLocal.day;
  }

  String _filtersSignature(CalendarFiltersState filters) {
    return [
      ...filters.choirs,
      '::',
      ...filters.voices,
      '::',
      ...filters.classNames,
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
