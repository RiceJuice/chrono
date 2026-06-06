import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/providers/event_schedules_providers.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/text_content.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/bottom_modal_expandable_text.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/bottom_modal_schedule_section.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/event_bottom_modal_typography.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BottomModalTextLayout {
  standard,
  event,
}

class BottomModalText extends ConsumerWidget {
  const BottomModalText({
    super.key,
    required this.entry,
    this.titleStyle,
    this.layout = BottomModalTextLayout.standard,
    this.includeScheduleSection = true,
  });

  final CalendarEntry entry;
  final TextStyle? titleStyle;
  final BottomModalTextLayout layout;
  final bool includeScheduleSection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEventLayout = layout == BottomModalTextLayout.event;

    if (isEventLayout) {
      return _EventBottomModalTextContent(
        entry: entry,
        titleStyle: titleStyle,
        includeScheduleSection: includeScheduleSection,
      );
    }

    return _StandardBottomModalTextContent(
      entry: entry,
      titleStyle: titleStyle,
    );
  }
}

class _EventBottomModalTextContent extends ConsumerWidget {
  const _EventBottomModalTextContent({
    required this.entry,
    this.titleStyle,
    this.includeScheduleSection = true,
  });

  final CalendarEntry entry;
  final TextStyle? titleStyle;
  final bool includeScheduleSection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final descriptionText = (entry.description ?? '').trim();
    final noteText = (entry.note ?? '').trim();
    final locationText = (entry.location ?? '').trim();
    final schedulesAsync = ref.watch(eventSchedulesForEntryProvider(entry.id));

    return Padding(
      padding: EdgeInsets.fromLTRB(
        EventBottomModalTypography.contentHorizontal,
        locationText.isNotEmpty
            ? EventBottomModalTypography.locationTop
            : EventBottomModalTypography.contentTop,
        EventBottomModalTypography.contentHorizontal,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (locationText.isNotEmpty) ...[
            CalendarEntryLocationRow(
              location: locationText,
              subtitleColor: scheme.onSurfaceVariant,
              mutedColor: scheme.onSurfaceVariant,
              textStyle: EventBottomModalTypography.eventLocation(scheme),
              iconSize: 17,
            ),
            const SizedBox(height: EventBottomModalTypography.gapAfterLocation),
          ],
          Text(
            entry.eventName,
            style: titleStyle ?? theme.textTheme.titleLarge,
          ),
          const SizedBox(height: EventBottomModalTypography.gapAfterTitle),
          Text(
            '${AppDateTime.formatLocalHourMinute(entry.startTime)} – '
            '${AppDateTime.formatLocalHourMinute(entry.endTime)} Uhr',
            style: EventBottomModalTypography.eventTime(scheme),
          ),
          if (descriptionText.isNotEmpty) ...[
            const SizedBox(height: EventBottomModalTypography.gapAfterTime),
            BottomModalExpandableTextSection(
              label: 'Beschreibung',
              text: descriptionText,
              labelStyle: EventBottomModalTypography.sectionLabelStyle(scheme),
              bodyStyle: EventBottomModalTypography.bodyStyle(scheme),
              labelGap: EventBottomModalTypography.gapLabelBody,
            ),
          ],
          if (noteText.isNotEmpty) ...[
            const SizedBox(height: EventBottomModalTypography.gapSection),
            BottomModalExpandableTextSection(
              label: 'Notiz',
              text: noteText,
              labelStyle: EventBottomModalTypography.sectionLabelStyle(scheme),
              bodyStyle: EventBottomModalTypography.bodyStyle(scheme),
              labelGap: EventBottomModalTypography.gapLabelBody,
            ),
          ],
          if (includeScheduleSection)
            schedulesAsync.when(
              data: (schedules) {
                if (schedules.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(
                    top: EventBottomModalTypography.gapSection,
                  ),
                  child: BottomModalScheduleSection(
                    schedules: schedules,
                    eventLayout: true,
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(top: EventBottomModalTypography.gapSection),
                child: SizedBox(
                  height: 40,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
              error: (_, _) => const SizedBox.shrink(),
            ),
          if (includeScheduleSection)
            const SizedBox(height: EventBottomModalTypography.contentBottom)
          else
            const SizedBox(height: AppSpacing.s),
        ],
      ),
    );
  }
}

class _StandardBottomModalTextContent extends ConsumerWidget {
  const _StandardBottomModalTextContent({
    required this.entry,
    this.titleStyle,
  });

  final CalendarEntry entry;
  final TextStyle? titleStyle;

  static const double _kContentTop = AppSpacing.m;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mutedColor = scheme.onSurface.withValues(
      alpha: AppOpacity.secondaryContent,
    );
    final sectionLabelStyle = theme.textTheme.labelLarge?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final mutedBodyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: mutedColor,
    );

    final descriptionText = (entry.description ?? '').trim();
    final noteText = (entry.note ?? '').trim();
    final locationText = (entry.location ?? '').trim();
    final schedulesAsync = ref.watch(eventSchedulesForEntryProvider(entry.id));

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.l, _kContentTop, AppSpacing.l, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (locationText.isNotEmpty) ...[
            CalendarEntryLocationRow(
              location: locationText,
              subtitleColor: scheme.onSurfaceVariant,
              mutedColor: scheme.onSurfaceVariant,
              textStyle: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              iconSize: 16,
            ),
            const SizedBox(height: AppSpacing.s),
          ],
          Text(
            entry.eventName,
            style: titleStyle ?? theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            '${AppDateTime.formatLocalHourMinute(entry.startTime)} – '
            '${AppDateTime.formatLocalHourMinute(entry.endTime)} Uhr',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (descriptionText.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.l),
            Text('Beschreibung', style: sectionLabelStyle),
            const SizedBox(height: AppSpacing.s),
            Text(descriptionText, style: mutedBodyStyle),
          ],
          if (noteText.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.l),
            Text('Notiz', style: sectionLabelStyle),
            const SizedBox(height: AppSpacing.s),
            Text(noteText, style: mutedBodyStyle),
          ],
          schedulesAsync.when(
            data: (schedules) {
              if (schedules.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.l),
                child: BottomModalScheduleSection(schedules: schedules),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.only(top: AppSpacing.l),
              child: SizedBox(
                height: 48,
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
