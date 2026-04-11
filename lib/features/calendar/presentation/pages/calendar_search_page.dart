import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/calendar_providers.dart';
import '../theme/calendar_presentation_theme.dart';
import '../widgets/event_list/cards/calendar_entry_card.dart';
import 'search_results/search_results_initial_scroll.dart';
import 'search_results/search_results_sections.dart';

class CalendarSearchPage extends ConsumerStatefulWidget {
  const CalendarSearchPage({required this.query, super.key});

  final String query;

  @override
  ConsumerState<CalendarSearchPage> createState() => _CalendarSearchPageState();
}

class _CalendarSearchPageState extends ConsumerState<CalendarSearchPage> {
  static const double _stickyHeaderHeight = 32;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _listViewportKey = GlobalKey();
  bool _didAutoScroll = false;
  String? _lastAnchorSignature;
  int _stickySectionIndex = 0;
  bool _showStickyHeader = false;
  double _stickyHeaderPushOffset = 0;
  bool _didTriggerStickyCollisionHaptic = false;

  @override
  void didUpdateWidget(covariant CalendarSearchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _didAutoScroll = false;
      _lastAnchorSignature = null;
      _stickySectionIndex = 0;
      _showStickyHeader = false;
      _stickyHeaderPushOffset = 0;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        final sections = sectionsResult.sections;
        final dayHeaderKeys = List<GlobalKey>.generate(
          sections.length,
          (_) => GlobalKey(),
        );
        final signature = '${entries.length}-${sectionsResult.initialSectionIndex}'
            '-${sectionsResult.firstUpcomingEntryId ?? 'none'}'
            '-${entries.first.id}-${entries.last.id}';
        if (!_didAutoScroll || _lastAnchorSignature != signature) {
          _lastAnchorSignature = signature;
          scheduleInitialSearchResultsScroll(
            controller: _scrollController,
            sectionKeys: dayHeaderKeys,
            targetSectionIndex: sectionsResult.initialSectionIndex,
            onScrolled: () {
              _didAutoScroll = true;
            },
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateStickyHeaderState(dayHeaderKeys);
        });

        final clampedStickyIndex = _stickySectionIndex.clamp(0, sections.length - 1);

        return Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                _updateStickyHeaderState(dayHeaderKeys);
                return false;
              },
              child: ListView.builder(
                key: _listViewportKey,
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: sections.length,
                itemBuilder: (context, index) {
                  final section = sections[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDayHeader(
                        context: context,
                        key: dayHeaderKeys[index],
                        day: section.day,
                      ),
                      for (final entry in section.entries)
                        CalendarEntryCard(
                          entry: entry,
                          applyPastStyling: true,
                        ),
                    ],
                  );
                },
              ),
            ),
            if (_showStickyHeader)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Transform.translate(
                    offset: Offset(0, _stickyHeaderPushOffset),
                    child: _buildDayHeader(
                      context: context,
                      day: sections[clampedStickyIndex].day,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const _DebouncedLoadingIndicator(),
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
    Key? key,
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
      key: key,
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

  void _updateStickyHeaderState(List<GlobalKey> dayHeaderKeys) {
    final viewportContext = _listViewportKey.currentContext;
    if (viewportContext == null || dayHeaderKeys.isEmpty) return;
    final viewportBox = viewportContext.findRenderObject() as RenderBox?;
    if (viewportBox == null) return;
    final viewportTop = viewportBox.localToGlobal(Offset.zero).dy;

    var currentIndex = 0;
    for (var i = 0; i < dayHeaderKeys.length; i++) {
      final headerContext = dayHeaderKeys[i].currentContext;
      if (headerContext == null) continue;
      final headerBox = headerContext.findRenderObject() as RenderBox?;
      if (headerBox == null) continue;
      final headerDy = headerBox.localToGlobal(Offset.zero).dy - viewportTop;
      if (headerDy <= 0) {
        currentIndex = i;
      } else {
        break;
      }
    }

    var pushOffset = 0.0;
    var isInStickyCollision = false;
    final nextIndex = currentIndex + 1;
    if (nextIndex < dayHeaderKeys.length) {
      final nextContext = dayHeaderKeys[nextIndex].currentContext;
      final nextBox = nextContext?.findRenderObject() as RenderBox?;
      if (nextBox != null) {
        final nextDy = nextBox.localToGlobal(Offset.zero).dy - viewportTop;
        if (nextDy < _stickyHeaderHeight) {
          isInStickyCollision = true;
          pushOffset = nextDy - _stickyHeaderHeight;
        }
      }
    }

    if (isInStickyCollision && !_didTriggerStickyCollisionHaptic) {
      HapticFeedback.mediumImpact();
      _didTriggerStickyCollisionHaptic = true;
    } else if (!isInStickyCollision && _didTriggerStickyCollisionHaptic) {
      _didTriggerStickyCollisionHaptic = false;
    }

    final showSticky = _scrollController.hasClients && _scrollController.offset > 0;
    if (currentIndex != _stickySectionIndex ||
        showSticky != _showStickyHeader ||
        pushOffset != _stickyHeaderPushOffset) {
      setState(() {
        _stickySectionIndex = currentIndex;
        _showStickyHeader = showSticky;
        _stickyHeaderPushOffset = pushOffset;
      });
    }
  }
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
