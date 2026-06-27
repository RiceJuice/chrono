import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/core/widgets/animated_circle_checkbox.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_subject.dart';
import 'package:chronoapp/features/homework/domain/models/homework_task.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_fragment_chip.dart';
import 'package:chronoapp/features/homework/presentation/helpers/homework_due_display.dart';
import 'package:flutter/material.dart';

class HomeworkTaskTile extends StatelessWidget {
  const HomeworkTaskTile({
    super.key,
    required this.task,
    required this.subject,
    required this.onToggleCompleted,
  });

  final HomeworkTask task;
  final CalendarSubject? subject;
  final ValueChanged<bool> onToggleCompleted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final completed = task.isCompleted;
    final contentColor = completed
        ? scheme.onSurface.withValues(alpha: 0.45)
        : scheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.s,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: AnimatedCircleCheckbox(
              selected: completed,
              size: 24,
              onChanged: (selected) {
                AppHaptics.selection();
                onToggleCompleted(selected);
              },
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subject != null) ...[
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: subject!.defaultColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s),
                      Expanded(
                        child: Text(
                          subject!.name,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: contentColor.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                if (task.fragments.isNotEmpty) ...[
                  Opacity(
                    opacity: completed ? 0.55 : 1,
                    child: HomeworkFragmentChipRow(
                      fragments: task.fragments,
                      compact: true,
                    ),
                  ),
                ] else if (task.title.isNotEmpty) ...[
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: contentColor,
                          decoration: completed ? TextDecoration.lineThrough : null,
                          decorationColor: contentColor.withValues(alpha: 0.6),
                        ),
                  ),
                ],
                if (task.displayDescription.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    task.displayDescription,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: contentColor.withValues(alpha: 0.85),
                          decoration: completed ? TextDecoration.lineThrough : null,
                          decorationColor: contentColor.withValues(alpha: 0.5),
                        ),
                  ),
                ],
                if (task.dueAt != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Fällig: ${formatHomeworkDueLabel(dueAt: task.dueAt!, dueSource: task.dueSource)}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: isHomeworkTaskOverdue(task: task)
                              ? scheme.error.withValues(alpha: 0.85)
                              : contentColor.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
