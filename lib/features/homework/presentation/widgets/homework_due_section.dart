import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/homework/domain/models/homework_task.dart';
import 'package:chronoapp/features/homework/presentation/helpers/homework_due_display.dart';
import 'package:chronoapp/features/homework/presentation/providers/homework_due_providers.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_form_shell.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_subject_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeworkDueSection extends ConsumerWidget {
  const HomeworkDueSection({
    super.key,
    required this.selectedSubjectId,
    required this.onSubjectChanged,
    required this.dueNextLesson,
    required this.onDueNextLessonChanged,
  });

  final String? selectedSubjectId;
  final ValueChanged<String?> onSubjectChanged;
  final bool dueNextLesson;
  final ValueChanged<bool> onDueNextLessonChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
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
        HomeworkFormField(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.l,
            vertical: AppSpacing.s,
          ),
          child: SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Bis nächste Stunde',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            subtitle: hasSubject
                ? null
                : Text(
                    'Zuerst ein Fach wählen',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
            value: dueNextLesson && hasSubject,
            onChanged: hasSubject
                ? (value) {
                    AppHaptics.selection();
                    onDueNextLessonChanged(value);
                  }
                : null,
          ),
        ),
        if (dueNextLesson && hasSubject)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              0,
              AppSpacing.l,
              AppSpacing.l,
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
                  message: 'Fällig vor $preview',
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
