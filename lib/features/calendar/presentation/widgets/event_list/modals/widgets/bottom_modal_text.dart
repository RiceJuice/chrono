import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_accent_overrides_provider.dart';
import 'package:chronoapp/features/calendar/presentation/providers/event_schedules_providers.dart';
import 'package:chronoapp/features/calendar/presentation/providers/lesson_weekdays_providers.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/text_content.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/bottom_modal_expandable_text.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/bottom_modal_schedule_section.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/event_bottom_modal_typography.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/features/school_assessments/domain/models/school_assessment_kind.dart';
import 'package:chronoapp/features/school_assessments/domain/school_assessment_lesson_lookup.dart';
import 'package:chronoapp/features/school_assessments/presentation/providers/school_assessment_providers.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_lesson_pending_hint.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/lesson_assessment_create_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BottomModalTextLayout {
  standard,
  event,
}

/// Welcher Abschnitt des Event-Textblocks gerendert wird (Sliver-Layout).
enum BottomModalEventTextPart {
  /// Titel, Beschreibung, Eckdaten, Notiz — wie bisher.
  full,

  /// Nur Event-Titel (sticky).
  titleOnly,

  /// Beschreibung, Eckdaten, Notiz — scrollt zwischen Titel und Ablauf.
  detailsOnly,
}

class BottomModalText extends ConsumerWidget {
  const BottomModalText({
    super.key,
    required this.entry,
    this.titleStyle,
    this.layout = BottomModalTextLayout.standard,
    this.includeScheduleSection = true,
    this.eventPart = BottomModalEventTextPart.full,
  });

  final CalendarEntry entry;
  final TextStyle? titleStyle;
  final BottomModalTextLayout layout;
  final bool includeScheduleSection;
  final BottomModalEventTextPart eventPart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEventLayout = layout == BottomModalTextLayout.event;

    if (isEventLayout) {
      return _EventBottomModalTextContent(
        entry: entry,
        titleStyle: titleStyle,
        includeScheduleSection: includeScheduleSection,
        part: eventPart,
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
    this.part = BottomModalEventTextPart.full,
  });

  final CalendarEntry entry;
  final TextStyle? titleStyle;
  final bool includeScheduleSection;
  final BottomModalEventTextPart part;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final descriptionText = (entry.description ?? '').trim();
    final noteText = (entry.note ?? '').trim();
    final locationText = (entry.location ?? '').trim();
    final schedulesAsync = ref.watch(eventSchedulesForEntryProvider(entry.id));

    if (part == BottomModalEventTextPart.titleOnly) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          EventBottomModalTypography.contentHorizontal,
          EventBottomModalTypography.contentTop,
          EventBottomModalTypography.contentHorizontal,
          0,
        ),
        child: Text(
          entry.eventName,
          style: titleStyle ?? theme.textTheme.titleLarge,
        ),
      );
    }

    final detailsColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (descriptionText.isNotEmpty) ...[
          const SizedBox(height: EventBottomModalTypography.gapAfterTitle),
          BottomModalExpandableTextSection(
            text: descriptionText,
            bodyStyle: EventBottomModalTypography.eventSubtitle(scheme),
          ),
        ],
        const SizedBox(height: EventBottomModalTypography.gapSection),
        _EventInlineInfoSection(
          startTime: entry.startTime,
          endTime: entry.endTime,
          location: locationText,
        ),
        if (noteText.isNotEmpty) ...[
          const SizedBox(height: EventBottomModalTypography.gapSection),
          BottomModalExpandableTextSection(
            label: 'NOTIZ',
            text: noteText,
            labelStyle: EventBottomModalTypography.sectionLabelStyle(scheme),
            bodyStyle: EventBottomModalTypography.bodyStyle(scheme),
            labelGap: EventBottomModalTypography.gapLabelBody,
          ),
        ],
        if (part == BottomModalEventTextPart.detailsOnly)
          const SizedBox(height: EventBottomModalTypography.gapSection),
      ],
    );

    if (part == BottomModalEventTextPart.detailsOnly) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: EventBottomModalTypography.contentHorizontal,
        ),
        child: detailsColumn,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EventBottomModalTypography.contentHorizontal,
        EventBottomModalTypography.contentTop,
        EventBottomModalTypography.contentHorizontal,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            entry.eventName,
            style: titleStyle ?? theme.textTheme.titleLarge,
          ),
          detailsColumn,
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

class _EventInlineInfoSection extends StatelessWidget {
  const _EventInlineInfoSection({
    required this.startTime,
    required this.endTime,
    required this.location,
  });

  final DateTime startTime;
  final DateTime endTime;
  final String location;

  String _formatDate() {
    if (AppDateTime.isSameLocalDay(startTime, endTime)) {
      return AppDateTime.formatLocalFullWeekdayDate(startTime);
    }

    return '${AppDateTime.formatLocalFullWeekdayDate(startTime)} – '
        '${AppDateTime.formatLocalFullWeekdayDate(endTime)}';
  }

  String _formatTimeRange() {
    return '${AppDateTime.formatLocalHourMinute(startTime)} – '
        '${AppDateTime.formatLocalHourMinute(endTime)} Uhr';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textStyle = EventBottomModalTypography.inlineInfoStyle(scheme);
    final iconColor = scheme.onSurfaceVariant.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EventInlineInfoRow(
          icon: Icons.calendar_today_rounded,
          text: _formatDate(),
          textStyle: textStyle,
          iconColor: iconColor,
        ),
        const SizedBox(height: EventBottomModalTypography.gapInlineInfoRows),
        _EventInlineInfoRow(
          icon: Icons.schedule_rounded,
          text: _formatTimeRange(),
          textStyle: textStyle,
          iconColor: iconColor,
        ),
        if (location.isNotEmpty) ...[
          const SizedBox(height: EventBottomModalTypography.gapInlineInfoRows),
          _EventInlineInfoRow(
            icon: Icons.place_outlined,
            text: location,
            textStyle: textStyle,
            iconColor: iconColor,
          ),
        ],
      ],
    );
  }
}

class _EventInlineInfoRow extends StatelessWidget {
  const _EventInlineInfoRow({
    required this.icon,
    required this.text,
    required this.textStyle,
    required this.iconColor,
  });

  final IconData icon;
  final String text;
  final TextStyle textStyle;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            size: EventBottomModalTypography.inlineInfoIconSize,
            color: iconColor,
          ),
        ),
        const SizedBox(width: EventBottomModalTypography.inlineInfoIconGap),
        Expanded(
          child: Text(
            text,
            style: textStyle,
          ),
        ),
      ],
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
    final isLesson = entry.type == CalendarEntryType.lesson;
    final assessmentLookupKey = isLesson
        ? schoolAssessmentLessonLookupKeyForEntry(entry)
        : null;
    final assessment = assessmentLookupKey == null
        ? null
        : ref.watch(schoolAssessmentForLessonKeyProvider(assessmentLookupKey));
    final lessonTitle = assessment?.kind.label ?? entry.eventName;
    final weekdaysAsync = isLesson
        ? ref.watch(
            lessonWeekdaysForEntryProvider(
              LessonWeekdaysLookup.fromEntry(entry),
            ),
          )
        : null;

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
            lessonTitle,
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
          if (isLesson && weekdaysAsync != null)
            weekdaysAsync.when(
              data: (weekdays) {
                final label = AppDateTime.formatLocalFullWeekdays(weekdays);
                if (label.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.s),
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          if (isLesson) ...[
            const SizedBox(height: AppSpacing.m),
            HomeworkLessonPendingHint(
              entry: entry,
              accentColor: resolveCalendarEntryAccent(ref, entry),
            ),
            LessonAssessmentCreateSection(entry: entry),
          ],
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
