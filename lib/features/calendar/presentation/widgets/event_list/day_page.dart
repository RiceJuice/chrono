import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/core/time/app_date_time.dart';
import '../../../data/calendar_image_prefetch.dart';
import '../../../domain/models/calendar_entry.dart';
import '../../providers/calendar_providers.dart';
import 'calendar_break_tile.dart';
import 'calendar_day_empty_state.dart';
import 'day_schedule_layout.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/calendar_now_anchor.dart';
import 'cards/calendar_entry_card.dart';

class DayPage extends ConsumerStatefulWidget {
  final DateTime date;
  const DayPage({super.key, required this.date});

  @override
  ConsumerState<DayPage> createState() => _DayPageState();
}

class _DayPageState extends ConsumerState<DayPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _nowAnchorKey = GlobalKey();
  Timer? _showScrollbarTimer;
  Timer? _hideScrollbarTimer;
  bool _didInitialScroll = false;
  bool _didScheduleInitialScrollbarReveal = false;
  bool _isScrollbarThumbVisible = false;
  bool _initialContentRevealed = true;

  static const Duration _initialScrollbarRevealDelay = Duration(
    milliseconds: 560,
  );
  static const Duration _initialScrollbarVisibleDuration = Duration(
    milliseconds: 900,
  );

  @override
  void dispose() {
    _showScrollbarTimer?.cancel();
    _hideScrollbarTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  int _entryIndexForNowAnchor(List<DayScheduleListItem> items) {
    return entryIndexForNowAnchorInDayItems(items);
  }

  Widget _buildLessonRow({
    required DayScheduleLessonRowItem item,
    required bool shouldApplyPastStyling,
  }) {
    final lessons = item.lessons;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < lessons.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.s),
              Expanded(
                child: CalendarEntryCard(
                  key: ValueKey<String>('calendar-entry-${lessons[i].id}'),
                  entry: lessons[i],
                  applyPastStyling: shouldApplyPastStyling,
                  showTimeColumn: i == 0,
                  listTileHorizontalPadding: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildListItem({
    required DayScheduleListItem item,
    required bool shouldApplyPastStyling,
  }) {
    return switch (item) {
      DayScheduleSingleItem(:final entry) => CalendarEntryCard(
        key: ValueKey<String>('calendar-entry-${entry.id}'),
        entry: entry,
        applyPastStyling: shouldApplyPastStyling,
      ),
      DayScheduleLessonRowItem() => _buildLessonRow(
        item: item,
        shouldApplyPastStyling: shouldApplyPastStyling,
      ),
    };
  }

  String _buildCombinedBreakLabel(List<CalendarEntry> breakEntries) {
    final names = <String>[];
    for (final entry in breakEntries) {
      final trimmed = entry.eventName.trim();
      if (trimmed.isEmpty || names.contains(trimmed)) continue;
      names.add(trimmed);
    }
    if (names.isEmpty) {
      return 'Ferien / Feiertag';
    }
    return names.join('  |  ');
  }

  Widget _buildBreakSummaryRow(List<CalendarEntry> breakEntries) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.l, right: AppSpacing.xs),
      child: CalendarBreakTile(
        label: _buildCombinedBreakLabel(breakEntries),
        centered: false,
      ),
    );
  }

  void _scheduleInitialScrollToNowAnchor() {
    if (!AppDateTime.isTodayLocal(widget.date) || _didInitialScroll) return;
    _didInitialScroll = true;
    _initialContentRevealed = false;
    CalendarNowAnchor.scheduleInitialJump(
      jump: () {
        final jumped = _jumpToNowAnchor();
        if (jumped && mounted) {
          setState(() => _initialContentRevealed = true);
        }
        return jumped;
      },
    );
    Future<void>.delayed(const Duration(milliseconds: 420), () {
      if (!mounted || _initialContentRevealed) return;
      setState(() => _initialContentRevealed = true);
    });
  }

  void _scheduleInitialScrollbarReveal() {
    if (_didScheduleInitialScrollbarReveal) return;
    _didScheduleInitialScrollbarReveal = true;

    _showScrollbarTimer?.cancel();
    _hideScrollbarTimer?.cancel();
    _showScrollbarTimer = Timer(_initialScrollbarRevealDelay, () {
      if (!mounted) return;
      setState(() {
        _isScrollbarThumbVisible = true;
      });
      _hideScrollbarTimer = Timer(_initialScrollbarVisibleDuration, () {
        if (!mounted) return;
        setState(() {
          _isScrollbarThumbVisible = false;
        });
      });
    });
  }

  bool _jumpToNowAnchor() {
    return CalendarNowAnchor.jumpToAnchor(
      anchorKey: _nowAnchorKey,
      controller: _scrollController,
    );
  }

  Widget _buildPlatformScrollbar({
    required BuildContext context,
    required Widget child,
  }) {
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return CupertinoScrollbar(
        controller: _scrollController,
        thumbVisibility: _isScrollbarThumbVisible,
        child: child,
      );
    }
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ScrollbarTheme(
      data: ScrollbarTheme.of(
        context,
      ).copyWith(thumbColor: WidgetStatePropertyAll<Color>(color)),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: _isScrollbarThumbVisible,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(
      filteredCalendarEntriesForDayProvider(widget.date),
    );
    final ownSchoolTracks = ref.watch(
      calendarFiltersProvider.select((filters) => filters.defaultSchoolTracks),
    );
    final shouldApplyPastStyling = AppDateTime.isTodayLocal(widget.date);

    return entriesAsync.when(
      data: (entries) {
        final breakEntries = entries
            .where((entry) => entry.type == CalendarEntryType.breakType)
            .toList(growable: false);
        final regularEntries = entries
            .where((entry) => entry.type != CalendarEntryType.breakType)
            .toList(growable: false);
        final listItems = buildDayScheduleListItems(
          entries: regularEntries,
          ownSchoolTracks: ownSchoolTracks,
        );
        final hasBreakSummary = breakEntries.isNotEmpty;

        if (regularEntries.isEmpty && !hasBreakSummary) {
          _didInitialScroll = false;
          _didScheduleInitialScrollbarReveal = false;
          return const CalendarDayEmptyState();
        }
        if (regularEntries.isEmpty && hasBreakSummary) {
          _didInitialScroll = false;
          _didScheduleInitialScrollbarReveal = false;
          return Stack(
            children: [
              const CalendarDayEmptyState(),
              Positioned(
                left: 0,
                right: 0,
                top: AppSpacing.m,
                child: _buildBreakSummaryRow(breakEntries),
              ),
            ],
          );
        }
        CalendarImagePrefetch.prefetchEntries(regularEntries);

        final isToday = AppDateTime.isTodayLocal(widget.date);
        final nowAnchorItemIndex = isToday
            ? _entryIndexForNowAnchor(listItems)
            : -1;
        final hasNowAnchor = isToday && listItems.isNotEmpty;
        final listStartOffset = hasBreakSummary ? 1 : 0;
        final nowAnchorBuilderIndex = hasNowAnchor
            ? listStartOffset + nowAnchorItemIndex
            : -1;
        if (hasNowAnchor) {
          _scheduleInitialScrollToNowAnchor();
        }
        _scheduleInitialScrollbarReveal();

        final listView = ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.only(
              top: AppSpacing.m,
              bottom: AppSpacing.m + MediaQuery.paddingOf(context).bottom,
            ),
            itemCount:
                listItems.length +
                (hasNowAnchor ? 1 : 0) +
                (hasBreakSummary ? 1 : 0),
            itemBuilder: (context, index) {
              final lastIndex =
                  listItems.length +
                  (hasNowAnchor ? 1 : 0) +
                  (hasBreakSummary ? 1 : 0) -
                  1;
              final Widget row;
              if (hasBreakSummary && index == 0) {
                row = _buildBreakSummaryRow(breakEntries);
              } else if (hasNowAnchor &&
                  index == nowAnchorBuilderIndex &&
                  listItems.isNotEmpty) {
                row = SizedBox(key: _nowAnchorKey, height: 1);
              } else {
                final localIndex = hasBreakSummary ? index - 1 : index;
                final isAfterNowAnchor =
                    hasNowAnchor &&
                    localIndex > nowAnchorBuilderIndex - listStartOffset;
                final itemIndex = isAfterNowAnchor
                    ? localIndex - 1
                    : localIndex;
                final item = listItems[itemIndex];
                row = _buildListItem(
                  item: item,
                  shouldApplyPastStyling: shouldApplyPastStyling,
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  row,
                  if (index != lastIndex) const SizedBox(height: AppSpacing.s),
                ],
              );
            },
          );

        return _buildPlatformScrollbar(
          context: context,
          child: Opacity(
            opacity: _initialContentRevealed ? 1.0 : 0.0,
            child: listView,
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Fehler: $err')),
    );
  }
}
