import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronoapp/core/time/app_date_time.dart';
import '../../../domain/models/calendar_entry.dart';
import '../../providers/calendar_providers.dart';
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
  bool _didInitialScroll = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isLessonEndingAt1015(CalendarEntry entry) {
    if (entry.type != CalendarEntryType.lesson) return false;
    final localEnd = AppDateTime.toLocal(entry.endTime);
    return localEnd.hour == 10 && localEnd.minute == 15;
  }

  int _entryIndexForNowAnchor(List<CalendarEntry> entries) {
    final now = DateTime.now();
    for (var i = 0; i < entries.length; i++) {
      final localEnd = AppDateTime.toLocal(entries[i].endTime);
      if (localEnd.isAfter(now)) return i;
    }
    return entries.length;
  }

  void _scheduleInitialScrollToNowAnchor() {
    if (!AppDateTime.isTodayLocal(widget.date) || _didInitialScroll) return;
    _didInitialScroll = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _jumpToNowAnchor();
      Future<void>.delayed(const Duration(milliseconds: 80), () {
        if (!mounted) return;
        _jumpToNowAnchor();
      });
    });
  }

  void _jumpToNowAnchor() {
    final anchorContext = _nowAnchorKey.currentContext;
    if (anchorContext == null) return;
    Scrollable.ensureVisible(
      anchorContext,
      alignment: 0.28,
      duration: Duration.zero,
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
        thumbVisibility: true,
        child: child,
      );
    }
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ScrollbarTheme(
      data: ScrollbarTheme.of(context).copyWith(
        thumbColor: WidgetStatePropertyAll<Color>(color),
      ),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(
      filteredCalendarEntriesForDayProvider(widget.date),
    );
    final shouldApplyPastStyling = AppDateTime.isTodayLocal(widget.date);

    return entriesAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          _didInitialScroll = false;
          return const Center(child: Text('Keine Einträge für diesen Tag.'));
        }
        final isToday = AppDateTime.isTodayLocal(widget.date);
        final nowAnchorEntryIndex = isToday ? _entryIndexForNowAnchor(entries) : -1;
        final hasNowAnchor = isToday;
        final nowAnchorBuilderIndex = hasNowAnchor ? nowAnchorEntryIndex : -1;
        _scheduleInitialScrollToNowAnchor();
        final hasLessonEndingAt1015 = entries.any(_isLessonEndingAt1015);
        int lessonCounter = 0;
        int? thirdLessonIndex;
        for (var i = 0; i < entries.length; i++) {
          if (entries[i].type != CalendarEntryType.lesson) continue;
          lessonCounter++;
          if (lessonCounter == 3) {
            thirdLessonIndex = i;
            break;
          }
        }

        return _buildPlatformScrollbar(
          context: context,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            itemCount: entries.length + (hasNowAnchor ? 1 : 0),
            itemBuilder: (context, index) {
              if (hasNowAnchor && index == nowAnchorBuilderIndex) {
                return SizedBox(key: _nowAnchorKey, height: 1);
              }
              final entryIndex =
                  hasNowAnchor && index > nowAnchorBuilderIndex ? index - 1 : index;
              final entry = entries[entryIndex];
              final hasFollowingEntry = entryIndex < entries.length - 1;
              final needsFallbackGapAfterThirdLesson =
                  !hasLessonEndingAt1015 && entryIndex == thirdLessonIndex;
              final needsMidMorningBreakGap =
                  hasFollowingEntry &&
                  (_isLessonEndingAt1015(entry) ||
                      needsFallbackGapAfterThirdLesson);
              return Padding(
                padding: EdgeInsets.only(
                  bottom: needsMidMorningBreakGap ? 12 : 0,
                ),
                child: CalendarEntryCard(
                  entry: entry,
                  applyPastStyling: shouldApplyPastStyling,
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Fehler: $err')),
    );
  }
}
