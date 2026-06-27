import 'package:chronoapp/core/auth/auth_user_id_provider.dart';
import 'package:chronoapp/core/database/database_provider.dart';
import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/providers/filter/calendar/calendar_filtered_entries_providers.dart';
import 'package:chronoapp/features/homework/data/homework_contribution_repository.dart';
import 'package:chronoapp/features/homework/data/homework_local_repository.dart';
import 'package:chronoapp/features/homework/data/homework_syntax_suggestion_repository.dart';
import 'package:chronoapp/features/homework/data/homework_task_repository.dart';
import 'package:chronoapp/features/homework/domain/current_lesson_for_subject.dart';
import 'package:chronoapp/features/homework/domain/homework_fragment_merge.dart';
import 'package:chronoapp/features/homework/domain/models/homework_contribution.dart';
import 'package:chronoapp/features/homework/domain/models/homework_fragment.dart';
import 'package:chronoapp/features/homework/domain/models/homework_syntax_suggestion.dart';
import 'package:chronoapp/features/homework/domain/models/homework_task.dart';
import 'package:chronoapp/features/login/domain/models/profile_gate_data.dart';
import 'package:chronoapp/features/login/presentation/providers/profile_gate_provider.dart';
import 'package:chronoapp/features/settings/data/models/profile_snapshot.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_active_child_id.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_calendar_viewer.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_child_permissions.dart';
import 'package:chronoapp/features/settings/presentation/providers/effective_calendar_profile_provider.dart';
import 'package:chronoapp/features/settings/presentation/providers/settings_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeworkLocalRepositoryProvider = Provider<HomeworkLocalRepository>((ref) {
  return HomeworkLocalRepository();
});

final homeworkTaskRepositoryProvider = Provider<HomeworkTaskRepository>((ref) {
  return HomeworkTaskRepository(ref.watch(dbProvider));
});

final homeworkContributionRepositoryProvider =
    Provider<HomeworkContributionRepository>((ref) {
  return HomeworkContributionRepository(ref.watch(dbProvider));
});

final homeworkSyntaxSuggestionRepositoryProvider =
    Provider<HomeworkSyntaxSuggestionRepository>((ref) {
  return HomeworkSyntaxSuggestionRepository(ref.watch(dbProvider));
});

final effectiveHomeworkProfileIdProvider = Provider<String?>((ref) {
  final userId = ref.watch(authUserIdProvider).value;
  if (userId == null) return null;

  final ownProfile = ref.watch(syncedProfileProvider).asData?.value;
  final gate = ref.watch(profileGateDataProvider);

  if (_isGuardianHomeworkViewer(gate: gate, ownProfile: ownProfile)) {
    final permissions = ref.watch(activeGuardianChildPermissionsProvider);
    if (!permissions.shareHomework) return null;
    return ref.watch(activeGuardianChildIdProvider);
  }

  return userId;
});

final effectiveHomeworkProfileProvider = Provider<ProfileSnapshot?>((ref) {
  return ref.watch(effectiveCalendarProfileProvider).asData?.value;
});

bool _isGuardianHomeworkViewer({
  required ProfileGateData gate,
  ProfileSnapshot? ownProfile,
}) {
  return isGuardianCalendarViewer(gate: gate, ownProfile: ownProfile);
}

final homeworkSyntaxSuggestionsProvider =
    StreamProvider<List<HomeworkSyntaxSuggestion>>((ref) {
  final repository = ref.watch(homeworkSyntaxSuggestionRepositoryProvider);
  return repository.watchSuggestions();
});

final homeworkClassContributionsProvider = StreamProvider.family<
    List<HomeworkContribution>, DateTime>((ref, lessonDate) {
  final profile = ref.watch(effectiveHomeworkProfileProvider);
  if (profile == null ||
      profile.className == null ||
      profile.className!.trim().isEmpty) {
    return Stream.value(const []);
  }

  final repository = ref.watch(homeworkContributionRepositoryProvider);
  return repository.watchClassContributions(
    className: profile.className!.trim(),
    schooltrack: profile.schoolTrack,
    lessonDate: lessonDate,
  );
});

final mergedClassFragmentsProvider = Provider.family<
    AsyncValue<List<HomeworkFragment>>, ({DateTime lessonDate, String? subjectId})>(
  (ref, args) {
    final contributions =
        ref.watch(homeworkClassContributionsProvider(args.lessonDate));
    return contributions.whenData(
      (list) => mergeClassFragments(
        list,
        subjectId: args.subjectId,
      ),
    );
  },
);

final currentLessonProvider = Provider<AsyncValue<CalendarEntry?>>((ref) {
  final today = AppDateTime.todayLocal();
  final entries = ref.watch(filteredCalendarEntriesForDayProvider(today));
  return entries.whenData((list) => pickCurrentLesson(entries: list));
});

final currentSubjectIdProvider = Provider<String?>((ref) {
  return ref.watch(currentLessonProvider).asData?.value?.subjectId;
});

final homeworkTasksProvider =
    AsyncNotifierProvider<HomeworkTasksNotifier, List<HomeworkTask>>(
  HomeworkTasksNotifier.new,
);

class HomeworkTasksNotifier extends AsyncNotifier<List<HomeworkTask>> {
  @override
  Future<List<HomeworkTask>> build() async {
    final profileId = ref.watch(effectiveHomeworkProfileIdProvider);
    if (profileId == null || profileId.isEmpty) return const [];

    await _migrateFromLocalIfNeeded(profileId);

    final repository = ref.watch(homeworkTaskRepositoryProvider);
    final initial = await repository.watchTasks(profileId).first;

    final subscription = repository.watchTasks(profileId).listen((tasks) {
      state = AsyncData(tasks);
    });
    ref.onDispose(subscription.cancel);

    return initial;
  }

  Future<void> _migrateFromLocalIfNeeded(String profileId) async {
    final localRepo = ref.read(homeworkLocalRepositoryProvider);
    final taskRepo = ref.read(homeworkTaskRepositoryProvider);
    final existingCount = await taskRepo.countTasks(profileId);
    if (existingCount > 0) return;

    final localTasks = await localRepo.loadTasks(profileId);
    if (localTasks.isEmpty) return;

    for (final task in localTasks) {
      final fragments = task.fragments.isNotEmpty
          ? task.fragments
          : task.description == null || task.description!.trim().isEmpty
              ? const <HomeworkFragment>[]
              : [
                  HomeworkFragment(
                    kind: HomeworkFragmentKind.freeText,
                    canonicalKey: 'text:${task.description!.trim().toLowerCase()}',
                    displayText: task.description!.trim(),
                    chipColorKey: 'default',
                    fields: {'text': task.description!.trim()},
                  ),
                ];

      await taskRepo.insertTask(
        profileId: profileId,
        title: task.title,
        fragments: fragments,
        description: task.description ?? task.plainText,
        subjectId: task.subjectId,
        dueAt: task.dueAt,
        dueSource: task.dueSource,
      );
    }

    await localRepo.clearTasks(profileId);
  }

  Future<void> addTask({
    required List<HomeworkFragment> fragments,
    String? description,
    String? subjectId,
    DateTime? dueAt,
    HomeworkDueSource? dueSource,
    String? contributionId,
  }) async {
    final profileId = ref.read(effectiveHomeworkProfileIdProvider);
    if (profileId == null || profileId.isEmpty) return;

    final title = fragmentsToPlainText(fragments);
    if (title.isEmpty) return;

    final repository = ref.read(homeworkTaskRepositoryProvider);
    await repository.insertTask(
      profileId: profileId,
      title: title,
      fragments: fragments,
      description: description,
      subjectId: subjectId,
      dueAt: dueAt,
      dueSource: dueSource,
      contributionId: contributionId,
    );
  }

  Future<void> toggleCompleted(String taskId) async {
    final profileId = ref.read(effectiveHomeworkProfileIdProvider);
    if (profileId == null || profileId.isEmpty) return;

    final current = state.asData?.value ?? await future;
    final task = current.where((t) => t.id == taskId).firstOrNull;
    if (task == null) return;

    final repository = ref.read(homeworkTaskRepositoryProvider);
    await repository.toggleCompleted(
      taskId: taskId,
      isCompleted: !task.isCompleted,
    );
  }
}
