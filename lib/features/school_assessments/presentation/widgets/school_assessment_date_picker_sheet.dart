import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_subject.dart';
import 'package:chronoapp/features/calendar/event_editor/presentation/widgets/pickers/event_date_time_pickers.dart';
import 'package:chronoapp/features/calendar/presentation/providers/subjects_providers.dart';
import 'package:chronoapp/features/calendar/presentation/providers/filter/calendar/calendar_filtered_entries_providers.dart';
import 'package:chronoapp/features/school_assessments/domain/subject_lesson_local_days.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

class SchoolAssessmentDatePickerSheet extends ConsumerStatefulWidget {
  const SchoolAssessmentDatePickerSheet({
    super.key,
    required this.initialDate,
    required this.subjectId,
  });

  final DateTime initialDate;
  final String subjectId;

  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initialDate,
    required String subjectId,
  }) {
    return AppModalSheet.show<DateTime>(
      context: context,
      showDragHandle: true,
      sheetAnimationStyle: kSettingsChoiceSheetMotion,
      builder: (sheetContext) {
        return AppModalSheetChrome(
          child: SchoolAssessmentDatePickerSheet(
            initialDate: initialDate,
            subjectId: subjectId,
          ),
        );
      },
    );
  }

  @override
  ConsumerState<SchoolAssessmentDatePickerSheet> createState() =>
      _SchoolAssessmentDatePickerSheetState();
}

class _SchoolAssessmentDatePickerSheetState
    extends ConsumerState<SchoolAssessmentDatePickerSheet> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = AppDateTime.localDay(widget.initialDate);
    _focusedDay = _selectedDay;
  }

  CalendarSubject? _findSubject(List<CalendarSubject> subjects) {
    final id = widget.subjectId.trim();
    for (final subject in subjects) {
      if (subject.id == id) return subject;
    }
    return null;
  }

  Widget? _dayBuilder({
    required BuildContext context,
    required DateTime day,
    required Set<DateTime> lessonDays,
    required Color subjectColor,
    required bool isOutside,
    required bool isToday,
    required bool isSelected,
  }) {
    final hasLesson = isSubjectLessonLocalDay(lessonDays: lessonDays, day: day);
    if (!hasLesson && !isSelected) return null;

    final scheme = Theme.of(context).colorScheme;
    final dayNumber = day.day;
    final textColor = switch ((isSelected, isOutside, isToday)) {
      (true, _, _) => subjectColor,
      (_, true, _) => scheme.onSurface.withValues(alpha: 0.35),
      (_, _, true) => subjectColor,
      _ => scheme.onSurface,
    };

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? subjectColor.withValues(alpha: 0.22)
              : hasLesson
                  ? subjectColor.withValues(alpha: isOutside ? 0.06 : 0.1)
                  : Colors.transparent,
          border: hasLesson
              ? Border.all(
                  color: subjectColor.withValues(alpha: isOutside ? 0.45 : 0.85),
                  width: isSelected ? 2.5 : 2,
                )
              : isSelected
                  ? Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.6),
                      width: 1.5,
                    )
                  : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '$dayNumber',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final entries = ref.watch(filteredCalendarAllEntriesProvider).asData?.value;
    final subjects = ref.watch(subjectsListProvider).asData?.value;
    final lessonDays = entries == null
        ? <DateTime>{}
        : subjectLessonLocalDays(
            entries: entries,
            subjectId: widget.subjectId,
          );
    final subject = subjects == null ? null : _findSubject(subjects);
    final subjectColor = subject?.defaultColor ?? scheme.primary;
    final subjectName = subject?.name;

    final now = AppDateTime.nowLocal();
    final firstDay = DateTime(now.year, now.month, now.day);
    final lastDay = firstDay.add(const Duration(days: 730));

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.m,
              AppSpacing.xl,
              AppSpacing.xs,
            ),
            child: Text(
              'Tag wählen',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          if (subjectName != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.s,
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: subjectColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: scheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Text(
                      'Umrandete Tage: $subjectName',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          TableCalendar<void>(
            locale: 'de_DE',
            startingDayOfWeek: StartingDayOfWeek.monday,
            firstDay: firstDay,
            lastDay: lastDay,
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            onDaySelected: (selectedDay, focusedDay) {
              AppHaptics.selection();
              setState(() {
                _selectedDay = AppDateTime.localDay(selectedDay);
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() => _focusedDay = focusedDay);
            },
            calendarFormat: CalendarFormat.month,
            availableGestures: AvailableGestures.horizontalSwipe,
            daysOfWeekHeight: 28,
            rowHeight: 42,
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              leftChevronIcon: Icon(
                Icons.chevron_left_rounded,
                color: scheme.onSurfaceVariant,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: true,
              defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
              weekendTextStyle: Theme.of(context).textTheme.bodyMedium!,
              outsideTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.35),
                  ),
              todayDecoration: const BoxDecoration(),
              selectedDecoration: const BoxDecoration(),
              markerDecoration: const BoxDecoration(),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) => _dayBuilder(
                context: context,
                day: day,
                lessonDays: lessonDays,
                subjectColor: subjectColor,
                isOutside: false,
                isToday: isSameDay(day, AppDateTime.localDay(now)),
                isSelected: isSameDay(day, _selectedDay),
              ),
              todayBuilder: (context, day, focusedDay) => _dayBuilder(
                context: context,
                day: day,
                lessonDays: lessonDays,
                subjectColor: subjectColor,
                isOutside: false,
                isToday: true,
                isSelected: isSameDay(day, _selectedDay),
              ),
              selectedBuilder: (context, day, focusedDay) => _dayBuilder(
                context: context,
                day: day,
                lessonDays: lessonDays,
                subjectColor: subjectColor,
                isOutside: false,
                isToday: isSameDay(day, AppDateTime.localDay(now)),
                isSelected: true,
              ),
              outsideBuilder: (context, day, focusedDay) => _dayBuilder(
                context: context,
                day: day,
                lessonDays: lessonDays,
                subjectColor: subjectColor,
                isOutside: true,
                isToday: isSameDay(day, AppDateTime.localDay(now)),
                isSelected: isSameDay(day, _selectedDay),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.m,
              AppSpacing.xl,
              AppSpacing.m + bottomInset,
            ),
            child: FilledButton(
              onPressed: () {
                AppHaptics.light();
                Navigator.of(context).pop(_selectedDay);
              },
              child: const Text('Übernehmen'),
            ),
          ),
        ],
      ),
    );
  }
}

String formatSchoolAssessmentLessonLabel(CalendarEntry lesson) {
  final local = lesson.startTime.toLocal();
  return '${AppDateTime.formatLocalFullWeekdayDate(local)}, '
      '${AppDateTime.formatLocalHourMinute(local)}';
}

String formatSchoolAssessmentCustomDayLabel(DateTime day) {
  return EventDateTimePickers.formatDate(day);
}
