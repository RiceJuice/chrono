import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/domain/filter/event_schedule_filter.dart';
import 'package:chronoapp/features/calendar/domain/models/event_schedule.dart';
import 'package:chronoapp/features/calendar/presentation/providers/filter/calendar/calendar_filters_provider.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/event_bottom_modal_typography.dart';
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
  });

  final List<EventSchedule> schedules;
  final bool eventLayout;

  @override
  ConsumerState<BottomModalScheduleSection> createState() =>
      _BottomModalScheduleSectionState();
}

class _BottomModalScheduleSectionState
    extends ConsumerState<BottomModalScheduleSection> {
  EventScheduleListFilter _filter = EventScheduleListFilter.all;

  static const Duration _collapseDuration = Duration(milliseconds: 420);
  static const Curve _collapseCurve = Curves.easeInOutCubic;

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

  void _setFilter(EventScheduleListFilter next) {
    if (_filter == next) return;
    AppHaptics.light();
    setState(() => _filter = next);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.schedules.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final gap = widget.eventLayout
        ? EventBottomModalTypography.gapScheduleCards
        : AppSpacing.s;

    ref.watch(calendarFiltersProvider);

    final visibleCount = widget.schedules
        .where((s) => _isVisible(s, _filter))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Ablauf',
              style: widget.eventLayout
                  ? EventBottomModalTypography.scheduleSectionLabel(scheme)
                  : Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
            ),
            if (_showFilterChips) ...[
              const Spacer(),
              _ScheduleFilterChip(
                label: 'Alle',
                selected: _filter == EventScheduleListFilter.all,
                onTap: () => _setFilter(EventScheduleListFilter.all),
              ),
              const SizedBox(width: 6),
              _ScheduleFilterChip(
                label: 'Meine',
                selected: _filter == EventScheduleListFilter.mine,
                onTap: () => _setFilter(EventScheduleListFilter.mine),
              ),
            ],
          ],
        ),
        SizedBox(
          height: widget.eventLayout
              ? EventBottomModalTypography.gapLabelBody
              : AppSpacing.s,
        ),
        AnimatedSize(
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
        ),
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
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
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
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.1,
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
              duration: duration * 0.65,
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
  });

  final EventSchedule schedule;
  final bool eventLayout;

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

    if (eventLayout) {
      final locationStyle = EventBottomModalTypography.scheduleCardLocationStyle(scheme);
      final locationColor = locationStyle.color!;

      return ClipSmoothRect(
        radius: AppSquircle.borderRadius(AppRadius.s),
        child: ColoredBox(
          color: scheme.surfaceContainerHighest,
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
                    Text(
                      schedule.title,
                      style: EventBottomModalTypography.scheduleCardTitleStyle(scheme),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        description,
                        style: EventBottomModalTypography.scheduleCardBodyStyle(scheme),
                      ),
                    ],
                  ],
                ),
              ),
              if (location.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    EventBottomModalTypography.cardLocationLeft,
                    description.isEmpty ? AppSpacing.xs : AppSpacing.xs,
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
                      Text(
                        _formatTimeRange(),
                        style: EventBottomModalTypography.scheduleCardTimeStyle(scheme),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    EventBottomModalTypography.cardHorizontal,
                    AppSpacing.xs,
                    EventBottomModalTypography.cardHorizontal,
                    EventBottomModalTypography.cardVertical,
                  ),
                  child: Text(
                    _formatTimeRange(),
                    style: EventBottomModalTypography.scheduleCardTimeStyle(scheme),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return ClipSmoothRect(
      radius: AppSquircle.borderRadius(AppRadius.s),
      child: ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: Padding(
          padding: AppInsets.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                schedule.title,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _formatTimeRange(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: mutedColor,
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
                      color: mutedColor,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        location,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: mutedColor,
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
                    color: mutedColor,
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
