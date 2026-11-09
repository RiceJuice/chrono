import 'package:chronoapp/features/homework/domain/models/homework_task.dart';
import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:chronoapp/core/widgets/main_shell_scaffold.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_subject.dart';
import 'package:chronoapp/features/calendar/presentation/providers/subjects_providers.dart';
import 'package:chronoapp/features/homework/domain/models/homework_peer_suggestion.dart';
import 'package:chronoapp/features/homework/presentation/providers/homework_providers.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_child_permissions.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_page_header.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_peer_suggestion_tile.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_create_form_sheet.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_task_swipe_to_delete.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_task_form_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeworkPage extends ConsumerWidget {
  const HomeworkPage({super.key});

  Future<void> _openCreateSheet(
    BuildContext context, {
    VoidCallback feedback = AppHaptics.light,
  }) async {
    if (AppModalSheetTracker.depth.value > 0) return;
    feedback();
    await HomeworkCreateFormSheet.show(context);
  }

  Future<void> _acceptSuggestion(
    BuildContext context,
    WidgetRef ref,
    HomeworkPeerSuggestion suggestion,
  ) async {
    try {
      await ref
          .read(homeworkTasksProvider.notifier)
          .acceptPeerSuggestion(suggestion);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aufgabe konnte nicht übernommen werden.'),
        ),
      );
    }
  }

  Future<bool> _confirmDeleteTask(
    BuildContext context,
    WidgetRef ref,
    String taskId,
  ) async {
    try {
      await ref.read(homeworkTasksProvider.notifier).deleteTask(taskId);
      return true;
    } catch (_) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aufgabe konnte nicht gelöscht werden.')),
      );
      return false;
    }
  }

  Future<void> _rejectSuggestion(
    BuildContext context,
    WidgetRef ref,
    HomeworkPeerSuggestion suggestion,
  ) async {
    try {
      await ref
          .read(homeworkTasksProvider.notifier)
          .rejectPeerSuggestion(suggestion);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vorschlag konnte nicht abgelehnt werden.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(visibleHomeworkTasksProvider);
    final peerSuggestionsAsync = ref.watch(pendingPeerSuggestionsProvider);
    final readOnly = ref.watch(isGuardianHomeworkReadOnlyProvider);
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
              onAddPressed: readOnly ? null : () => _openCreateSheet(context),
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
                  final peerSuggestions =
                      peerSuggestionsAsync.asData?.value ?? const [];
                  final isLoadingPeer =
                      peerSuggestionsAsync.isLoading &&
                      peerSuggestionsAsync.asData == null;

                  if (tasks.isEmpty && peerSuggestions.isEmpty) {
                    if (isLoadingPeer) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return _HomeworkEmptyState(
                      onCreate: readOnly
                          ? null
                          : () => _openCreateSheet(context),
                    );
                  }

                  final sortedTasks = sortHomeworkTasksByDueDay(
                    tasks,
                    subjectName: (id) => subjectsById[id]?.name ?? '',
                  );
                  final itemCount = peerSuggestions.length + tasks.length;

                  return ListView.builder(
                    padding: EdgeInsets.only(
                      bottom:
                          mainShellBottomContentInset(context) + AppSpacing.l,
                    ),
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      if (index < peerSuggestions.length) {
                        final suggestion = peerSuggestions[index];
                        final subject = subjectsById[suggestion.subjectId];

                        return HomeworkPeerSuggestionTile(
                          suggestion: suggestion,
                          subject: subject,
                          onAccept: readOnly
                              ? null
                              : () =>
                                    _acceptSuggestion(context, ref, suggestion),
                          onReject: readOnly
                              ? null
                              : () =>
                                    _rejectSuggestion(context, ref, suggestion),
                        );
                      }

                      final task = sortedTasks[index - peerSuggestions.length];
                      final subject = task.subjectId == null
                          ? null
                          : subjectsById[task.subjectId];

                      return HomeworkTaskSwipeToDelete(
                        key: ValueKey(task.id),
                        onEdit: readOnly
                            ? null
                            : () => HomeworkTaskFormSheet.show(
                                context,
                                task: task,
                              ),
                        task: task,
                        subject: subject,
                        onToggleCompleted: readOnly
                            ? null
                            : (_) {
                                ref
                                    .read(homeworkTasksProvider.notifier)
                                    .toggleCompleted(task.id);
                              },
                        onConfirmDelete: readOnly
                            ? null
                            : () => _confirmDeleteTask(context, ref, task.id),
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

class _HomeworkEmptyState extends StatelessWidget {
  const _HomeworkEmptyState({required this.onCreate});

  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const accent = Color(0xFF0B4AA5);
    final buttonRadius = BorderRadius.circular(AppRadius.m);

    return Padding(
      padding: EdgeInsets.only(bottom: mainShellBottomContentInset(context)),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Noch keine Aufgaben.',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              if (onCreate != null) ...[
                const SizedBox(height: AppSpacing.s),
                Text(
                  'Erstelle deine erste Aufgabe.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: buttonRadius,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40072B63),
                        offset: Offset(0, 10),
                        blurRadius: 18,
                      ),
                      BoxShadow(color: Color(0xFF07377E), offset: Offset(0, 4)),
                    ],
                  ),
                  child: SizedBox(
                    width: 88,
                    height: 56,
                    child: IconButton.filled(
                      tooltip: 'Neue Aufgabe erstellen',
                      enableFeedback: false,
                      style: IconButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: buttonRadius,
                          side: const BorderSide(color: Color(0x26FFFFFF)),
                        ),
                      ),
                      onPressed: onCreate,
                      icon: const Icon(CupertinoIcons.plus, size: 27),
                    ),
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
