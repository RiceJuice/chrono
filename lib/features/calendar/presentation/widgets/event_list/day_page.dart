import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
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
  Timer? _showScrollbarTimer;
  Timer? _hideScrollbarTimer;
  bool _didInitialScroll = false;
  bool _didScheduleInitialScrollbarReveal = false;
  bool _isScrollbarThumbVisible = false;

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

  void _jumpToNowAnchor() {
    final anchorContext = _nowAnchorKey.currentContext;
    if (anchorContext == null) return;
    final anchorRenderObject = anchorContext.findRenderObject();
    if (anchorRenderObject == null || !_scrollController.hasClients) return;

    final viewport = RenderAbstractViewport.maybeOf(anchorRenderObject);
    if (viewport == null) return;

    final position = _scrollController.position;
    final targetOffset = viewport.getOffsetToReveal(
      anchorRenderObject,
      0.28,
    ).offset;
    _scrollController.jumpTo(
      targetOffset.clamp(position.minScrollExtent, position.maxScrollExtent),
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
      data: ScrollbarTheme.of(context).copyWith(
        thumbColor: WidgetStatePropertyAll<Color>(color),
      ),
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
    final shouldApplyPastStyling = AppDateTime.isTodayLocal(widget.date);

    return entriesAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          _didInitialScroll = false;
          _didScheduleInitialScrollbarReveal = false;
          return const Center(child: Text('Keine Einträge für diesen Tag.'));
        }
        final isToday = AppDateTime.isTodayLocal(widget.date);
        final nowAnchorEntryIndex = isToday
            ? _entryIndexForNowAnchor(entries)
            : -1;
        final hasNowAnchor = isToday;
        final nowAnchorBuilderIndex = hasNowAnchor ? nowAnchorEntryIndex : -1;
        _scheduleInitialScrollToNowAnchor();
        _scheduleInitialScrollbarReveal();
        return _buildPlatformScrollbar(
          context: context,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
            itemCount: entries.length + (hasNowAnchor ? 1 : 0),
            itemBuilder: (context, index) {
              final lastIndex = entries.length + (hasNowAnchor ? 1 : 0) - 1;
              final Widget row;
              if (hasNowAnchor && index == nowAnchorBuilderIndex) {
                row = SizedBox(key: _nowAnchorKey, height: 1);
              } else {
                final entryIndex = hasNowAnchor && index > nowAnchorBuilderIndex
                    ? index - 1
                    : index;
                final entry = entries[entryIndex];
                row = CalendarEntryCard(
                  entry: entry,
                  applyPastStyling: shouldApplyPastStyling,
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  row,
                  if (index != lastIndex) const SizedBox(height: AppSpacing.m),
                ],
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
