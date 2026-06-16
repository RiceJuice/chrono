import 'dart:async';

import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/core/widgets/event_schedule_scroll_coordinator.dart';
import 'package:chronoapp/features/calendar/domain/filter/event_schedule_filter.dart';
import 'package:chronoapp/features/calendar/domain/models/event_schedule.dart';
import 'package:chronoapp/features/calendar/presentation/providers/filter/calendar/calendar_filters_provider.dart';
import 'package:chronoapp/features/calendar/presentation/theme/calendar_presentation_theme.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/calendar_now_anchor.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/event_bottom_modal_typography.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/event_modal_sticky_header.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/schedule_scroll_edge_hint.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// iOS-Systemblau für Ablauf-Filter-Chips.
const Color _kScheduleFilterChipBlue = Color(0xFF007AFF);

class BottomModalScheduleSection extends ConsumerStatefulWidget {
  const BottomModalScheduleSection({
    super.key,
    required this.schedules,
    this.eventLayout = false,
    this.scrollable = false,
    this.sheetScrollController,
    this.scrollCoordinator,
    this.stickyImages,
    this.stickyTitleBlock,
    this.scrollableDetailBlock,
    this.stickyHeaderSurfaceColor,
  });

  final List<EventSchedule> schedules;
  final bool eventLayout;
  final bool scrollable;
  final ScrollController? sheetScrollController;
  final EventScheduleScrollCoordinator? scrollCoordinator;

  /// Scrollt weg — nur bei [scrollable] + [stickyHeaderSurfaceColor].
  final Widget? stickyImages;

  /// Nur Event-Titel — gepinnt.
  final Widget? stickyTitleBlock;

  /// Beschreibung, Eckdaten, Notiz — scrollt zwischen Titel und Ablauf.
  final Widget? scrollableDetailBlock;

  /// Sheet-Hintergrund für den gepinnten Block.
  final Color? stickyHeaderSurfaceColor;

  @override
  ConsumerState<BottomModalScheduleSection> createState() =>
      _BottomModalScheduleSectionState();
}

class _BottomModalScheduleSectionState
    extends ConsumerState<BottomModalScheduleSection>
    with SingleTickerProviderStateMixin {
  EventScheduleListFilter _filter = EventScheduleListFilter.all;

  static const Duration _collapseDuration = Duration(milliseconds: 420);
  static const Curve _collapseCurve = Curves.easeInOutCubic;
  static const double _scrollUpHintOffsetThreshold = 8;

  final ScrollController _scheduleScrollController = ScrollController();
  GlobalKey _nowAnchorKey = GlobalKey();
  bool _didInitialScroll = false;

  /// Nutzer hat die Liste berührt — ausstehende Anker-Sprünge abbrechen.
  bool _userAdjustedScheduleScroll = false;

  late final AnimationController _scrollUpHintPulseController;
  ScrollController? _attachedScrollController;
  double _lastScrollOffset = 0;
  bool _showScrollUpHint = false;
  bool _scrollHintHasHiddenAbove = false;

  ScrollController? get _activeScrollController =>
      widget.scrollable ? widget.sheetScrollController : _scheduleScrollController;

  @override
  void initState() {
    super.initState();
    _scrollUpHintPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    widget.scrollCoordinator?.onUserScroll = _cancelPendingAnchorJump;
    _attachActiveScrollListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryScheduleInitialAnchorJump();
    });
  }

  @override
  void didUpdateWidget(covariant BottomModalScheduleSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollCoordinator != widget.scrollCoordinator) {
      oldWidget.scrollCoordinator?.onUserScroll = null;
      widget.scrollCoordinator?.onUserScroll = _cancelPendingAnchorJump;
    }
    if (oldWidget.schedules.isEmpty && widget.schedules.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryScheduleInitialAnchorJump();
      });
    }
    if (oldWidget.schedules != widget.schedules) {
      _nowAnchorKey = GlobalKey();
    }
    _attachActiveScrollListener();
  }

  @override
  void dispose() {
    _detachActiveScrollListener();
    _scrollUpHintPulseController.dispose();
    widget.scrollCoordinator?.onUserScroll = null;
    if (!widget.scrollable) {
      _scheduleScrollController.dispose();
    }
    super.dispose();
  }

  void _attachActiveScrollListener() {
    final controller = _activeScrollController;
    if (controller == _attachedScrollController) return;
    _detachActiveScrollListener();
    _attachedScrollController = controller;
    controller?.addListener(_onActiveScroll);
  }

  void _detachActiveScrollListener() {
    _attachedScrollController?.removeListener(_onActiveScroll);
    _attachedScrollController = null;
  }

  void _onActiveScroll() {
    if (!mounted) return;

    final controller = _activeScrollController;
    if (controller == null || !controller.hasClients || !widget.scrollable) {
      return;
    }

    final offset = controller.offset;
    final scrollingDown = offset > _lastScrollOffset + 0.5;
    _lastScrollOffset = offset;

    final hasHiddenAbove = _scrollHintHasHiddenAbove;
    final pastThreshold = offset > _scrollUpHintOffsetThreshold;
    final shouldShow = hasHiddenAbove && pastThreshold;

    if (scrollingDown && shouldShow) {
      if (!_showScrollUpHint) {
        setState(() => _showScrollUpHint = true);
      }
      if (mounted) {
        unawaited(_scrollUpHintPulseController.forward(from: 0));
      }
    } else if (!shouldShow && _showScrollUpHint) {
      setState(() => _showScrollUpHint = false);
    }
  }

  void _cancelPendingAnchorJump() {
    if (_userAdjustedScheduleScroll) return;
    _userAdjustedScheduleScroll = true;
  }

  bool _shouldContinueAnchorJump() =>
      mounted && !_userAdjustedScheduleScroll;

  void _tryScheduleInitialAnchorJump() {
    if (!mounted || !widget.scrollable || widget.schedules.isEmpty) return;
    final anchorIndex = CalendarNowAnchor.scheduleAnchorIndex(
      widget.schedules,
      isVisible: (schedule) => _isVisible(schedule, _filter),
    );
    _scheduleInitialScrollToNowAnchor(anchorIndex);
  }

  bool _isVisible(
    EventSchedule schedule,
    EventScheduleListFilter filter,
  ) {
    if (filter == EventScheduleListFilter.all) return true;
    final filters = ref.read(calendarFiltersProvider);
    return eventScheduleMatchesUserProfile(
      schedule: schedule,
      filters: filters,
    );
  }

  bool get _showFilterChips {
    if (!widget.eventLayout || widget.schedules.isEmpty) return false;
    return widget.schedules.any(
      (s) => s.choirs.isNotEmpty || s.voices.isNotEmpty,
    );
  }

  List<EventSchedule> get _filterVisibleSchedules => widget.schedules
      .where((schedule) => _isVisible(schedule, _filter))
      .toList(growable: false);

  int? _anchorScheduleIndex(List<EventSchedule> visibleSchedules) {
    return CalendarNowAnchor.scheduleAnchorIndex(
      widget.schedules,
      isVisible: (schedule) =>
          visibleSchedules.any((item) => item.id == schedule.id),
    );
  }

  bool _jumpToNowAnchor() {
    final controller = _activeScrollController;
    if (!_shouldContinueAnchorJump() ||
        controller == null ||
        !controller.hasClients) {
      return true;
    }
    return CalendarNowAnchor.jumpToAnchor(
      anchorKey: _nowAnchorKey,
      controller: controller,
    );
  }

  void _scheduleInitialScrollToNowAnchor(int? anchorScheduleIndex) {
    if (anchorScheduleIndex == null ||
        !widget.scrollable ||
        _didInitialScroll ||
        _userAdjustedScheduleScroll) {
      return;
    }
    _didInitialScroll = true;

    void runJump() {
      if (!mounted || _userAdjustedScheduleScroll) return;
      CalendarNowAnchor.scheduleInitialJump(
        jump: _jumpToNowAnchor,
        shouldContinue: _shouldContinueAnchorJump,
      );
    }

    final coordinator = widget.scrollCoordinator;
    if (coordinator != null) {
      coordinator.runWhenAnchorScrollViewportReady(runJump);
    } else {
      runJump();
    }
  }

  void _setFilter(EventScheduleListFilter next) {
    if (_filter == next) return;
    AppHaptics.light();
    setState(() {
      _filter = next;
      _didInitialScroll = false;
      _userAdjustedScheduleScroll = false;
      _showScrollUpHint = false;
      _lastScrollOffset = 0;
      _nowAnchorKey = GlobalKey();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryScheduleInitialAnchorJump();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.schedules.isEmpty) return const SizedBox.shrink();

    ref.watch(calendarFiltersProvider);

    final scheme = Theme.of(context).colorScheme;
    final gap = widget.eventLayout
        ? EventBottomModalTypography.gapScheduleCards
        : AppSpacing.s;
    final visibleSchedules = _filterVisibleSchedules;
    final visibleCount = visibleSchedules.length;
    final anchorScheduleIndex = widget.scrollable
        ? _anchorScheduleIndex(visibleSchedules)
        : null;
    _scrollHintHasHiddenAbove =
        anchorScheduleIndex != null && anchorScheduleIndex > 0;

    final header = _ScheduleSectionHeader(
      scheme: scheme,
      eventLayout: widget.eventLayout,
      showFilterChips: _showFilterChips,
      filter: _filter,
      onFilterChanged: _setFilter,
    );

    if (!widget.scrollable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          header,
          SizedBox(
            height: widget.eventLayout
                ? EventBottomModalTypography.gapLabelBody
                : AppSpacing.s,
          ),
          _buildStaticList(gap: gap, visibleCount: visibleCount),
        ],
      );
    }

    final useStickyHeader =
        widget.scrollable && widget.stickyHeaderSurfaceColor != null;

    if (useStickyHeader) {
      return SliverMainAxisGroup(
        slivers: [
          if (widget.stickyImages != null)
            EventModalCollapsingImageHeaderSliver(
              child: widget.stickyImages!,
            ),
          if (widget.stickyTitleBlock != null)
            EventModalStickyHeaderSliver(
              backgroundColor: widget.stickyHeaderSurfaceColor!,
              child: widget.stickyTitleBlock!,
            ),
          if (widget.scrollableDetailBlock != null)
            SliverToBoxAdapter(child: widget.scrollableDetailBlock!),
          EventModalStickyHeaderSliver(
            backgroundColor: widget.stickyHeaderSurfaceColor!,
            allowChildOverflow: true,
            child: _buildStickyAblaufHeader(header),
          ),
          _buildScheduleSliverList(
            gap: gap,
            anchorScheduleIndex: anchorScheduleIndex,
            visibleCount: visibleCount,
            includeTopPadding: false,
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: EventBottomModalTypography.contentBottom),
          ),
        ],
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              EventBottomModalTypography.contentHorizontal,
              widget.eventLayout
                  ? EventBottomModalTypography.gapSection
                  : 0,
              EventBottomModalTypography.contentHorizontal,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                header,
                SizedBox(
                  height: widget.eventLayout
                      ? EventBottomModalTypography.gapLabelBody
                      : AppSpacing.s,
                ),
              ],
            ),
          ),
        ),
        _buildScheduleSliverList(
          gap: gap,
          anchorScheduleIndex: anchorScheduleIndex,
          visibleCount: visibleCount,
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: EventBottomModalTypography.contentBottom),
        ),
      ],
    );
  }

  /// Gepinnter Block: nur „Ablauf“-Zeile inkl. Abstand zur ersten Karte.
  Widget _buildStickyAblaufHeader(Widget scheduleHeader) {
    final scheme = Theme.of(context).colorScheme;
    final surfaceColor = widget.stickyHeaderSurfaceColor ?? scheme.surface;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            EventBottomModalTypography.contentHorizontal,
            0,
            EventBottomModalTypography.contentHorizontal,
            widget.eventLayout
                ? EventBottomModalTypography.gapAfterScheduleHeader
                : 0,
          ),
          child: scheduleHeader,
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: -ScheduleScrollEdgeHint.height,
          child: ScheduleScrollEdgeHint(
            direction: ScheduleScrollHintDirection.up,
            visible: _showScrollUpHint,
            pulse: _scrollUpHintPulseController,
            surfaceColor: surfaceColor,
            iconColor: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Ablauf-Einträge als [SliverList] — ein Scroll mit dem Sheet, kein Nested-Scroll.
  Widget _buildScheduleSliverList({
    required double gap,
    required int? anchorScheduleIndex,
    required int visibleCount,
    bool includeTopPadding = true,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final hasLeadGap =
        anchorScheduleIndex != null && anchorScheduleIndex > 0;
    final showEmptyMine =
        _filter == EventScheduleListFilter.mine && visibleCount == 0;
    final anchorExtra = anchorScheduleIndex != null ? 1 : 0;
    final itemCount =
        widget.schedules.length + anchorExtra + (showEmptyMine ? 1 : 0);

    return SliverPadding(
      padding: EdgeInsets.only(top: includeTopPadding ? 8 : 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (showEmptyMine && index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                EventBottomModalTypography.contentHorizontal,
                8,
                EventBottomModalTypography.contentHorizontal,
                0,
              ),
              child: Text(
                'Keine Termine für dein Profil.',
                style: EventBottomModalTypography.bodyStyle(scheme).copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            );
          }

          final listOffset = showEmptyMine ? 1 : 0;
          final builderIndex = index - listOffset;

          if (anchorScheduleIndex != null &&
              builderIndex == anchorScheduleIndex) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: EventBottomModalTypography.contentHorizontal,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (hasLeadGap)
                    const SizedBox(
                      height:
                          EventBottomModalTypography.scheduleNowAnchorLeadGap,
                    ),
                  SizedBox(key: _nowAnchorKey, height: 1),
                ],
              ),
            );
          }

          final scheduleIndex = anchorScheduleIndex != null &&
                  builderIndex > anchorScheduleIndex
              ? builderIndex - 1
              : builderIndex;

          return RepaintBoundary(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: EventBottomModalTypography.contentHorizontal,
              ),
              child: _buildScheduleRow(
                schedule: widget.schedules[scheduleIndex],
                gapAfter: gap,
                isLast: scheduleIndex == widget.schedules.length - 1,
              ),
            ),
          );
        },
        childCount: itemCount,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
      ),
      ),
    );
  }

  Widget _buildStaticList({
    required double gap,
    required int visibleCount,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedSize(
      duration: _collapseDuration,
      curve: _collapseCurve,
      alignment: Alignment.topCenter,
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < widget.schedules.length; i++)
            _CollapsingScheduleSlot(
              key: ValueKey(widget.schedules[i].id),
              visible: _isVisible(widget.schedules[i], _filter),
              gapAfter: i < widget.schedules.length - 1 ? gap : 0,
              duration: _collapseDuration,
              curve: _collapseCurve,
              child: _ScheduleItemCard(
                schedule: widget.schedules[i],
                eventLayout: widget.eventLayout,
              ),
            ),
          if (_filter == EventScheduleListFilter.mine && visibleCount == 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s),
              child: Text(
                'Keine Termine für dein Profil.',
                style: EventBottomModalTypography.bodyStyle(scheme).copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow({
    required EventSchedule schedule,
    required double gapAfter,
    required bool isLast,
  }) {
    return _CollapsingScheduleSlot(
      key: ValueKey('schedule-${schedule.id}'),
      visible: _isVisible(schedule, _filter),
      gapAfter: isLast ? 0 : gapAfter,
      duration: _collapseDuration,
      curve: _collapseCurve,
      child: _ScheduleItemCard(
        schedule: schedule,
        eventLayout: widget.eventLayout,
        applyPastStyling: CalendarNowAnchor.scheduleApplyPastStyling(schedule),
      ),
    );
  }
}

class _ScheduleSectionHeader extends StatelessWidget {
  const _ScheduleSectionHeader({
    required this.scheme,
    required this.eventLayout,
    required this.showFilterChips,
    required this.filter,
    required this.onFilterChanged,
  });

  final ColorScheme scheme;
  final bool eventLayout;
  final bool showFilterChips;
  final EventScheduleListFilter filter;
  final ValueChanged<EventScheduleListFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          eventLayout ? 'ABLAUF' : 'Ablauf',
          style: eventLayout
              ? EventBottomModalTypography.scheduleSectionLabel(scheme)
              : Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
        ),
        if (showFilterChips) ...[
          const Spacer(),
          _ScheduleFilterChip(
            label: 'Alle',
            selected: filter == EventScheduleListFilter.all,
            onTap: () => onFilterChanged(EventScheduleListFilter.all),
          ),
          const SizedBox(width: EventBottomModalTypography.filterChipGap),
          _ScheduleFilterChip(
            label: 'Meine',
            selected: filter == EventScheduleListFilter.mine,
            onTap: () => onFilterChanged(EventScheduleListFilter.mine),
          ),
        ],
      ],
    );
  }
}

class _ScheduleFilterChip extends StatelessWidget {
  const _ScheduleFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOutCubic,
          padding: EventBottomModalTypography.filterChipPadding,
          decoration: BoxDecoration(
            color: selected
                ? _kScheduleFilterChipBlue
                : _kScheduleFilterChipBlue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(100),
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOutCubic,
            style: TextStyle(
              fontSize: EventBottomModalTypography.filterChipFontSize,
              fontWeight: FontWeight.w600,
              height: 1.15,
              color: selected ? Colors.white : _kScheduleFilterChipBlue,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

class _CollapsingScheduleSlot extends StatelessWidget {
  const _CollapsingScheduleSlot({
    super.key,
    required this.visible,
    required this.gapAfter,
    required this.duration,
    required this.curve,
    required this.child,
  });

  final bool visible;
  final double gapAfter;
  final Duration duration;
  final Curve curve;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRect(
          child: AnimatedAlign(
            duration: duration,
            curve: curve,
            alignment: Alignment.topCenter,
            heightFactor: visible ? 1 : 0,
            child: AnimatedOpacity(
              duration: Duration(
                milliseconds: (duration.inMilliseconds * 0.65).round(),
              ),
              curve: curve,
              opacity: visible ? 1 : 0,
              child: child,
            ),
          ),
        ),
        AnimatedContainer(
          duration: duration,
          curve: curve,
          height: visible ? gapAfter : 0,
        ),
      ],
    );
  }
}

class _ScheduleItemCard extends StatelessWidget {
  const _ScheduleItemCard({
    required this.schedule,
    required this.eventLayout,
    this.applyPastStyling = false,
  });

  final EventSchedule schedule;
  final bool eventLayout;
  final bool applyPastStyling;

  String _formatTimeRange() {
    final start = AppDateTime.formatLocalHourMinute(schedule.startTime);
    final end = schedule.endTime;
    if (end == null) return start;
    return '$start – ${AppDateTime.formatLocalHourMinute(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final description = (schedule.description ?? '').trim();
    final location = (schedule.location ?? '').trim();
    final mutedColor = scheme.onSurface.withValues(alpha: AppOpacity.secondaryContent);
    final isPast = CalendarNowAnchor.scheduleIsPast(schedule);
    final usePastStyle = applyPastStyling && isPast;

    if (eventLayout) {
      final baseCardColor = scheme.surfaceContainerHighest;
      final cardColor = usePastStyle
          ? CalendarPresentationTheme.dimmedSurface(context, baseCardColor)
          : baseCardColor;
      final primaryTextColor = usePastStyle
          ? CalendarPresentationTheme.pastTextColor(context)
          : scheme.onSurface;
      final secondaryTextColor = usePastStyle
          ? CalendarPresentationTheme.pastMutedTextColor(context)
          : scheme.onSurface.withValues(alpha: 0.54);

      final titleStyle = EventBottomModalTypography.scheduleCardTitleStyle(scheme)
          .copyWith(color: primaryTextColor);
      final bodyStyle = EventBottomModalTypography.scheduleCardBodyStyle(scheme)
          .copyWith(color: primaryTextColor);
      final timeStyle = EventBottomModalTypography.scheduleCardTimeStyle(scheme)
          .copyWith(color: secondaryTextColor);
      final locationStyle = EventBottomModalTypography.scheduleCardLocationStyle(
        scheme,
      ).copyWith(
        color: usePastStyle
            ? CalendarPresentationTheme.pastMutedTextColor(context)
            : EventBottomModalTypography.scheduleCardLocationStyle(scheme).color,
      );
      final locationColor = locationStyle.color!;

      return ClipSmoothRect(
        radius: AppSquircle.borderRadius(AppRadius.s),
        child: ColoredBox(
          color: cardColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  EventBottomModalTypography.cardHorizontal,
                  EventBottomModalTypography.cardVertical,
                  EventBottomModalTypography.cardHorizontal,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(schedule.title, style: titleStyle),
                    if (description.isNotEmpty) ...[
                      const SizedBox(
                        height: EventBottomModalTypography.scheduleCardTitleBodyGap,
                      ),
                      Text(description, style: bodyStyle),
                    ],
                  ],
                ),
              ),
              if (location.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    EventBottomModalTypography.cardLocationLeft,
                    EventBottomModalTypography.scheduleCardBodyLocationGap,
                    EventBottomModalTypography.cardHorizontal,
                    EventBottomModalTypography.cardVertical,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.place_outlined,
                              size: 18,
                              color: locationColor,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                location,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: locationStyle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s),
                      Text(_formatTimeRange(), style: timeStyle),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    EventBottomModalTypography.cardHorizontal,
                    EventBottomModalTypography.scheduleCardBodyLocationGap,
                    EventBottomModalTypography.cardHorizontal,
                    EventBottomModalTypography.cardVertical,
                  ),
                  child: Text(_formatTimeRange(), style: timeStyle),
                ),
            ],
          ),
        ),
      );
    }

    final cardColor = usePastStyle
        ? CalendarPresentationTheme.dimmedSurface(
            context,
            scheme.surfaceContainerHighest,
          )
        : scheme.surfaceContainerHighest;
    final pastMuted = CalendarPresentationTheme.pastMutedTextColor(context);

    return ClipSmoothRect(
      radius: AppSquircle.borderRadius(AppRadius.s),
      child: ColoredBox(
        color: cardColor,
        child: Padding(
          padding: AppInsets.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                schedule.title,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: usePastStyle
                      ? CalendarPresentationTheme.pastTextColor(context)
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _formatTimeRange(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: usePastStyle ? pastMuted : mutedColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (location.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 16,
                      color: usePastStyle ? pastMuted : mutedColor,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        location,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: usePastStyle ? pastMuted : mutedColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: usePastStyle ? pastMuted : mutedColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
