import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:chronoapp/core/widgets/main_shell_scaffold.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_subject.dart';
import 'package:chronoapp/features/calendar/presentation/providers/subjects_providers.dart';
import 'package:chronoapp/features/homework/presentation/providers/homework_providers.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_page_header.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_task_form_sheet.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_task_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeworkPage extends ConsumerWidget {
  const HomeworkPage({super.key});

  Future<void> _openCreateSheet(BuildContext context) async {
    if (AppModalSheetTracker.depth.value > 0) return;
    AppHaptics.light();
    await HomeworkTaskFormSheet.show(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(homeworkTasksProvider);
    final subjectsAsync = ref.watch(subjectsListProvider);
    final subjectsById = subjectsAsync.asData?.value == null
        ? <String, CalendarSubject>{}
        : {
            for (final subject in subjectsAsync.asData!.value)
              subject.id: subject,
          };

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeworkPageHeader(
              onAddPressed: () => _openCreateSheet(context),
            ),
            Expanded(
              child: tasksAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: Text(
                    'Aufgaben konnten nicht geladen werden.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                        child: Text(
                          'Noch keine Aufgaben.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.only(
                      bottom: mainShellBottomContentInset(context) + AppSpacing.l,
                    ),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      final subject = task.subjectId == null
                          ? null
                          : subjectsById[task.subjectId];

                      return HomeworkTaskTile(
                        task: task,
                        subject: subject,
                        onToggleCompleted: (_) {
                          ref
                              .read(homeworkTasksProvider.notifier)
                              .toggleCompleted(task.id);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
