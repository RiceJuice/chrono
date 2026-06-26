import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/event_editor/presentation/widgets/pickers/event_date_time_pickers.dart';
import 'package:chronoapp/features/calendar/event_editor/presentation/widgets/pickers/event_inline_date_picker.dart';
import 'package:chronoapp/features/homework/domain/models/homework_task.dart';
import 'package:chronoapp/features/homework/presentation/helpers/homework_due_display.dart';
import 'package:chronoapp/features/homework/presentation/providers/homework_due_providers.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_form_shell.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_subject_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum HomeworkDueMode {
  none,
  nextLesson,
  customDate,
}

class HomeworkDueSection extends ConsumerWidget {
  const HomeworkDueSection({
    super.key,
    required this.selectedSubjectId,
    required this.onSubjectChanged,
    required this.mode,
    required this.onModeChanged,
    required this.customDueDate,
    required this.onCustomDueDateChanged,
  });

  final String? selectedSubjectId;
  final ValueChanged<String?> onSubjectChanged;
  final HomeworkDueMode mode;
  final ValueChanged<HomeworkDueMode> onModeChanged;
  final DateTime customDueDate;
  final ValueChanged<DateTime> onCustomDueDateChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSubject =
        selectedSubjectId != null && selectedSubjectId!.trim().isNotEmpty;
    final nextLessonAsync = hasSubject
        ? ref.watch(nextLessonForSubjectProvider(selectedSubjectId))
        : const AsyncData<CalendarEntry?>(null);

    return HomeworkFormGroup(
      children: [
        HomeworkSubjectPickerRow(
          selectedSubjectId: selectedSubjectId,
          onSubjectChanged: onSubjectChanged,
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeworkFormSegmentedControl<HomeworkDueMode>(
                value: mode,
                onChanged: (next) {
                  AppHaptics.selection();
                  onModeChanged(next);
                },
                segments: [
                  const HomeworkFormSegment(
                    value: HomeworkDueMode.none,
                    label: 'Keine',
                  ),
                  HomeworkFormSegment(
                    value: HomeworkDueMode.nextLesson,
                    label: 'Nächste Stunde',
                    enabled: hasSubject,
                  ),
                  const HomeworkFormSegment(
                    value: HomeworkDueMode.customDate,
                    label: 'Datum',
                  ),
                ],
              ),
              if (mode == HomeworkDueMode.nextLesson) ...[
                const SizedBox(height: AppSpacing.m),
                nextLessonAsync.when(
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
                      message: 'Fällig vor $preview',
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        if (mode == HomeworkDueMode.customDate)
          HomeworkFormPickerRow(
            label: 'Fällig am',
            value: EventDateTimePickers.formatDate(customDueDate),
            onTap: () => _HomeworkDatePickerSheet.show(
              context,
              initialDate: customDueDate,
              onChanged: onCustomDueDateChanged,
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
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppSpacing.s),
        Expanded(
          child: Text(
            message,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}

class _HomeworkDatePickerSheet extends StatefulWidget {
  const _HomeworkDatePickerSheet({
    required this.initialDate,
    required this.onChanged,
  });

  final DateTime initialDate;
  final ValueChanged<DateTime> onChanged;

  static Future<void> show(
    BuildContext context, {
    required DateTime initialDate,
    required ValueChanged<DateTime> onChanged,
  }) {
    return AppModalSheet.show<void>(
      context: context,
      showDragHandle: true,
      sheetAnimationStyle: kSettingsChoiceSheetMotion,
      builder: (sheetContext) {
        return AppModalSheetChrome(
          child: _HomeworkDatePickerSheet(
            initialDate: initialDate,
            onChanged: onChanged,
          ),
        );
      },
    );
  }

  @override
  State<_HomeworkDatePickerSheet> createState() =>
      _HomeworkDatePickerSheetState();
}

class _HomeworkDatePickerSheetState extends State<_HomeworkDatePickerSheet> {
  late DateTime _value = widget.initialDate;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

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
              AppSpacing.s,
            ),
            child: Text(
              'Fälligkeitsdatum',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          EventInlineDatePicker(
            value: _value,
            onChanged: (date) => setState(() => _value = date),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.s,
              AppSpacing.xl,
              AppSpacing.m + bottomInset,
            ),
            child: FilledButton(
              onPressed: () {
                AppHaptics.light();
                widget.onChanged(_value);
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.l),
                ),
              ),
              child: const Text('Übernehmen'),
            ),
          ),
        ],
      ),
    );
  }
}
