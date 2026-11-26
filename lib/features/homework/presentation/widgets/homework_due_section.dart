import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/homework/domain/models/homework_task.dart';
import 'package:chronoapp/features/homework/presentation/helpers/homework_due_display.dart';
import 'package:chronoapp/features/homework/presentation/providers/homework_due_providers.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_form_shell.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_subject_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeworkDueSection extends ConsumerWidget {
  const HomeworkDueSection({
    super.key,
    required this.selectedSubjectId,
    required this.onSubjectChanged,
    required this.dueNextLesson,
    required this.onDueNextLessonChanged,
    required this.selectedDay,
    required this.onDayChanged,
  });

  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDayChanged;
  final String? selectedSubjectId;
  final ValueChanged<String?> onSubjectChanged;
  final bool dueNextLesson;
  final ValueChanged<bool> onDueNextLessonChanged;

  static String formatDay(DateTime day) =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSubject =
        selectedSubjectId != null && selectedSubjectId!.trim().isNotEmpty;
    final nextLessonAsync = hasSubject
        ? ref.watch(nextLessonForSubjectProvider(selectedSubjectId))
        : const AsyncData<CalendarEntry?>(null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeworkFormGroup(
          children: [
            HomeworkSubjectPickerRow(
              selectedSubjectId: selectedSubjectId,
              onSubjectChanged: onSubjectChanged,
            ),
            HomeworkFormField(
              child: HomeworkFormSegmentedControl<bool>(
                value: dueNextLesson && hasSubject,
                onChanged: (value) {
                  AppHaptics.selection();
                  onDueNextLessonChanged(value);
                },
                segments: [
                  HomeworkFormSegment(
                    value: true,
                    label: 'Nächste Stunde',
                    enabled: hasSubject,
                  ),
                  const HomeworkFormSegment(
                    value: false,
                    label: 'Anderes Datum',
                  ),
                ],
              ),
            ),
            if (!dueNextLesson || !hasSubject) ...[
              HomeworkFormPickerRow(
                label: 'Abgabetag',
                value: selectedDay == null
                    ? 'Auswählen'
                    : '${selectedDay!.day}.${selectedDay!.month}.${selectedDay!.year}',
                onTap: () async {
                  FocusManager.instance.primaryFocus?.unfocus();
                  final today = DateUtils.dateOnly(DateTime.now());
                  final initial =
                      selectedDay != null && !selectedDay!.isBefore(today)
                      ? selectedDay!
                      : today;
                  final last = DateTime(today.year + 5, 12, 31);
                  final platform = Theme.of(context).platform;
                  try {
                    if (platform == TargetPlatform.iOS ||
                        platform == TargetPlatform.android) {
                      final result =
                          await const MethodChannel(
                            'chrono/homework_date',
                          ).invokeMethod<String>('pickDate', {
                            'initial': formatDay(initial),
                            'minimum': formatDay(today),
                            'maximum': formatDay(last),
                          });
                      if (context.mounted && result != null) {
                        onDayChanged(DateTime.parse(result));
                      }
                    } else {
                      final result = await showDatePicker(
                        context: context,
                        initialDate: initial,
                        firstDate: today,
                        lastDate: last,
                      );
                      if (context.mounted && result != null) {
                        onDayChanged(result);
                      }
                    }
                  } on PlatformException {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Kalender konnte nicht geöffnet werden. Bitte erneut versuchen.',
                        ),
                      ),
                    );
                  } on MissingPluginException {
                    if (!context.mounted) return;
                    final result = await showCupertinoModalPopup<DateTime>(
                      context: context,
                      builder: (pickerContext) {
                        var date = initial;
                        return Container(
                          height: 360,
                          color: CupertinoColors.systemBackground.resolveFrom(
                            pickerContext,
                          ),
                          child: SafeArea(
                            top: false,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    CupertinoButton(
                                      onPressed: () =>
                                          Navigator.pop(pickerContext),
                                      child: const Text('Abbrechen'),
                                    ),
                                    CupertinoButton(
                                      onPressed: () =>
                                          Navigator.pop(pickerContext, date),
                                      child: const Text('Fertig'),
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: CupertinoDatePicker(
                                    mode: CupertinoDatePickerMode.date,
                                    initialDateTime: initial,
                                    minimumDate: today,
                                    maximumDate: last,
                                    onDateTimeChanged: (value) => date = value,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                    if (context.mounted && result != null) onDayChanged(result);
                  }
                },
              ),
              if (selectedDay != null && hasSubject)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: ref
                      .watch(
                        lessonForSubjectOnDayProvider((
                          subjectId: selectedSubjectId!,
                          day: selectedDay!,
                        )),
                      )
                      .when(
                        loading: () => const Text('Stunde wird gesucht …'),
                        error: (_, _) =>
                            const Text('Kalender konnte nicht geladen werden.'),
                        data: (lesson) => Text(
                          lesson == null
                              ? 'An diesem Tag kein Unterricht in diesem Fach. Fällig am gewählten Datum.'
                              : 'Fällig um ${TimeOfDay.fromDateTime(lesson.startTime.toLocal()).format(context)} Uhr',
                        ),
                      ),
                ),
            ],
          ],
        ),
        if (!hasSubject)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _CompactDueHint(
              icon: Icons.info_outline_rounded,
              message:
                  'Wähle ein Fach für die nächste Stunde oder lege ein eigenes Datum fest.',
            ),
          ),
        if (dueNextLesson && hasSubject)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.m,
              AppSpacing.l,
              0,
            ),
            child: nextLessonAsync.when(
              loading: () => const _CompactDueHint(
                icon: Icons.schedule_rounded,
                message: 'Stunde wird gesucht …',
              ),
              error: (_, _) => const _CompactDueHint(
                icon: Icons.error_outline_rounded,
                message: 'Kalender nicht geladen',
                isError: true,
              ),
              data: (lesson) {
                if (lesson == null) {
                  return const _CompactDueHint(
                    icon: Icons.event_busy_rounded,
                    message: 'Keine kommende Stunde',
                    isError: true,
                  );
                }

                final preview = formatHomeworkDueLabel(
                  dueAt: lesson.startTime,
                  dueSource: HomeworkDueSource.nextLesson,
                );
                return _CompactDueHint(
                  icon: Icons.schedule_rounded,
                  message: 'Fällig zum Unterrichtsbeginn: $preview',
                );
              },
            ),
          ),
      ],
    );
  }
}

class _CompactDueHint extends StatelessWidget {
  const _CompactDueHint({
    required this.icon,
    required this.message,
    this.isError = false,
  });

  final IconData icon;
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isError ? scheme.error : scheme.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: AppSpacing.s),
        Expanded(
          child: Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color, height: 1.45),
          ),
        ),
      ],
    );
  }
}
