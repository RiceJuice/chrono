import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/homework/domain/homework_tasks_for_lesson.dart';
import 'package:chronoapp/features/homework/domain/models/homework_task.dart';
import 'package:chronoapp/features/homework/presentation/helpers/homework_due_display.dart';
import 'package:chronoapp/features/homework/presentation/providers/homework_lesson_providers.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_fragment_chip.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_child_permissions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeworkLessonPendingHint extends ConsumerWidget {
  const HomeworkLessonPendingHint({
    super.key,
    required this.entry,
    this.accentColor,
  });

  final CalendarEntry entry;
  final Color? accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (entry.type != CalendarEntryType.lesson) {
      return const SizedBox.shrink();
    }

    final lookupKey = lessonHomeworkLookupKeyForEntry(entry);
    final openTasks = lookupKey == null
        ? const <HomeworkTask>[]
        : ref.watch(openHomeworkTasksForLessonKeyProvider(lookupKey));
    if (openTasks.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final accent = accentColor ?? entry.accentColor;
    final hasOverdue = openTasks.any(
      (task) => isHomeworkTaskOverdue(task: task),
    );
    final headlineColor = hasOverdue
        ? scheme.error.withValues(alpha: 0.9)
        : scheme.onSurfaceVariant;
    final canNavigate = ref.watch(guardianHomeworkTabVisibleProvider);

    final headline = openTasks.length == 1
        ? 'Noch 1 Aufgabe offen'
        : 'Noch ${openTasks.length} Aufgaben offen';

    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: AppSquircle.borderRadius(AppRadius.m),
        border: Border(
          left: BorderSide(
            color: accent.withValues(alpha: 0.65),
            width: 3,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.m,
          AppSpacing.s,
          AppSpacing.m,
          AppSpacing.s,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(
                Icons.assignment_outlined,
                size: 18,
                color: headlineColor,
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: headlineColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (openTasks.length == 1) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _SingleTaskPreview(task: openTasks.first),
                  ],
                ],
              ),
            ),
            if (canNavigate)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.xs, top: 1),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
                ),
              ),
          ],
        ),
      ),
    );

    if (!canNavigate) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppSquircle.borderRadius(AppRadius.m),
        onTap: () {
          AppHaptics.light();
          Navigator.of(context).pop();
          context.go('/homework');
        },
        child: content,
      ),
    );
  }
}

class _SingleTaskPreview extends StatelessWidget {
  const _SingleTaskPreview({required this.task});

  final HomeworkTask task;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (task.fragments.isNotEmpty) {
      return HomeworkFragmentChipRow(
        fragments: task.fragments,
        compact: true,
      );
    }

    final title = task.title.trim();
    if (title.isEmpty) return const SizedBox.shrink();

    return Text(
      title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
            fontWeight: FontWeight.w500,
          ),
    );
  }
}
