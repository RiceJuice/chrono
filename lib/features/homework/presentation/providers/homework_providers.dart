import 'package:chronoapp/core/auth/auth_user_id_provider.dart';
import 'package:chronoapp/features/homework/data/homework_local_repository.dart';
import 'package:chronoapp/features/homework/domain/models/homework_task.dart';
import 'package:chronoapp/features/login/domain/models/profile_gate_data.dart';
import 'package:chronoapp/features/login/presentation/providers/profile_gate_provider.dart';
import 'package:chronoapp/features/settings/data/models/profile_snapshot.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_active_child_id.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_calendar_viewer.dart';
import 'package:chronoapp/features/settings/presentation/providers/settings_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeworkLocalRepositoryProvider = Provider<HomeworkLocalRepository>((ref) {
  return HomeworkLocalRepository();
});

final effectiveHomeworkProfileIdProvider = Provider<String?>((ref) {
  final userId = ref.watch(authUserIdProvider).value;
  if (userId == null) return null;

  final ownProfile = ref.watch(syncedProfileProvider).asData?.value;
  final gate = ref.watch(profileGateDataProvider);

  if (_isGuardianHomeworkViewer(gate: gate, ownProfile: ownProfile)) {
    return ref.watch(activeGuardianChildIdProvider);
  }

  return userId;
});

bool _isGuardianHomeworkViewer({
  required ProfileGateData gate,
  ProfileSnapshot? ownProfile,
}) {
  return isGuardianCalendarViewer(gate: gate, ownProfile: ownProfile);
}

final homeworkTasksProvider =
    AsyncNotifierProvider<HomeworkTasksNotifier, List<HomeworkTask>>(
  HomeworkTasksNotifier.new,
);

class HomeworkTasksNotifier extends AsyncNotifier<List<HomeworkTask>> {
  @override
  Future<List<HomeworkTask>> build() async {
    final profileId = ref.watch(effectiveHomeworkProfileIdProvider);
    if (profileId == null || profileId.isEmpty) return const [];

    final repository = ref.watch(homeworkLocalRepositoryProvider);
    final tasks = await repository.loadTasks(profileId);
    return sortHomeworkTasks(tasks);
  }

  Future<void> addTask({
    required String title,
    String? description,
    String? subjectId,
    DateTime? dueAt,
    HomeworkDueSource? dueSource,
  }) async {
    final profileId = ref.read(effectiveHomeworkProfileIdProvider);
    if (profileId == null || profileId.isEmpty) return;

    final repository = ref.read(homeworkLocalRepositoryProvider);
    final current = state.asData?.value ?? await future;
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) return;

    final trimmedDescription = description?.trim();
    final nextTask = HomeworkTask(
      id: repository.createTaskId(),
      title: trimmedTitle,
      description: trimmedDescription == null || trimmedDescription.isEmpty
          ? null
          : trimmedDescription,
      subjectId: subjectId,
      isCompleted: false,
      createdAt: DateTime.now(),
      dueAt: dueAt,
      dueSource: dueSource,
    );

    final next = sortHomeworkTasks([nextTask, ...current]);
    state = AsyncData(next);
    await repository.saveTasks(profileId, next);
  }

  Future<void> toggleCompleted(String taskId) async {
    final profileId = ref.read(effectiveHomeworkProfileIdProvider);
    if (profileId == null || profileId.isEmpty) return;

    final repository = ref.read(homeworkLocalRepositoryProvider);
    final current = state.asData?.value ?? await future;
    final next = sortHomeworkTasks(
      current.map((task) {
        if (task.id != taskId) return task;
        final completed = !task.isCompleted;
        return task.copyWith(
          isCompleted: completed,
          completedAt: completed ? DateTime.now() : null,
          clearCompletedAt: !completed,
        );
      }),
    );

    state = AsyncData(next);
    await repository.saveTasks(profileId, next);
  }
}
