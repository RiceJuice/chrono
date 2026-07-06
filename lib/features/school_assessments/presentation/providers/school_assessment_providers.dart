import 'package:chronoapp/core/auth/auth_user_id_provider.dart';
import 'package:chronoapp/core/database/database_provider.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/providers/filter/calendar/calendar_filtered_entries_providers.dart';
import 'package:chronoapp/features/login/domain/models/profile_gate_data.dart';
import 'package:chronoapp/features/login/presentation/providers/profile_gate_provider.dart';
import 'package:chronoapp/features/school_assessments/data/school_assessment_repository.dart';
import 'package:chronoapp/features/school_assessments/domain/models/school_assessment.dart';
import 'package:chronoapp/features/school_assessments/domain/models/school_assessment_kind.dart';
import 'package:chronoapp/features/school_assessments/domain/models/school_assessment_schedule_source.dart';
import 'package:chronoapp/features/school_assessments/domain/school_assessment_lesson_lookup.dart';
import 'package:chronoapp/features/settings/data/models/profile_snapshot.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_active_child_id.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_calendar_viewer.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_child_permissions.dart';
import 'package:chronoapp/features/settings/presentation/providers/settings_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final schoolAssessmentRepositoryProvider =
    Provider<SchoolAssessmentRepository>((ref) {
  return SchoolAssessmentRepository(ref.watch(dbProvider));
});

final effectiveSchoolAssessmentProfileIdProvider = Provider<String?>((ref) {
  final userId = ref.watch(authUserIdProvider).value;
  if (userId == null) return null;

  final ownProfile = ref.watch(syncedProfileProvider).asData?.value;
  final gate = ref.watch(profileGateDataProvider);

  if (_isGuardianSchoolViewer(gate: gate, ownProfile: ownProfile)) {
    final permissions = ref.watch(activeGuardianChildPermissionsProvider);
    if (!permissions.shareSchool) return null;
    return ref.watch(activeGuardianChildIdProvider);
  }

  return userId;
});

bool _isGuardianSchoolViewer({
  required ProfileGateData gate,
  ProfileSnapshot? ownProfile,
}) {
  return isGuardianCalendarViewer(gate: gate, ownProfile: ownProfile);
}

/// Schüler dürfen erstellen; Eltern im Kind-Kalender nur lesen.
final canCreateSchoolAssessmentProvider = Provider<bool>((ref) {
  final gate = ref.watch(profileGateDataProvider);
  final ownProfile = ref.watch(syncedProfileProvider).asData?.value;
  return !isGuardianCalendarViewer(gate: gate, ownProfile: ownProfile);
});

final schoolAssessmentsProvider =
    StreamProvider<List<SchoolAssessment>>((ref) {
  final profileId = ref.watch(effectiveSchoolAssessmentProfileIdProvider);
  if (profileId == null || profileId.isEmpty) {
    return const Stream<List<SchoolAssessment>>.empty();
  }
  return ref
      .watch(schoolAssessmentRepositoryProvider)
      .watchAssessments(profileId);
});

final schoolAssessmentsByLessonKeyProvider =
    Provider<Map<String, SchoolAssessment>>((ref) {
  final assessments = ref.watch(schoolAssessmentsProvider).asData?.value;
  if (assessments == null) return const {};
  return indexSchoolAssessmentsByLessonKey(assessments);
});

final schoolAssessmentPreviewsByLessonKeyProvider =
    Provider<Map<String, SchoolAssessment>>((ref) {
  final assessments = ref.watch(schoolAssessmentsProvider).asData?.value;
  final lessons = ref.watch(filteredCalendarAllEntriesProvider).asData?.value;
  if (assessments == null || lessons == null) return const {};
  return indexSchoolAssessmentPreviewsByLessonKey(
    assessments: assessments,
    lessons: lessons,
  );
});

final schoolAssessmentForLessonKeyProvider =
    Provider.family<SchoolAssessment?, String>((ref, key) {
  return ref.watch(schoolAssessmentsByLessonKeyProvider)[key];
});

final schoolAssessmentPreviewForLessonKeyProvider =
    Provider.family<SchoolAssessment?, String>((ref, key) {
  return ref.watch(schoolAssessmentPreviewsByLessonKeyProvider)[key];
});

typedef CreateSchoolAssessmentParams = ({
  SchoolAssessmentKind kind,
  String subjectId,
  DateTime scheduledAt,
  SchoolAssessmentScheduleSource scheduleSource,
});

final schoolAssessmentActionsProvider = Provider<SchoolAssessmentActions>((ref) {
  return SchoolAssessmentActions(ref);
});

class SchoolAssessmentActions {
  SchoolAssessmentActions(this._ref);

  final Ref _ref;

  Future<void> create(CreateSchoolAssessmentParams params) async {
    final profileId = _ref.read(effectiveSchoolAssessmentProfileIdProvider);
    if (profileId == null || profileId.isEmpty) return;

    await _ref.read(schoolAssessmentRepositoryProvider).insertAssessment(
          profileId: profileId,
          kind: params.kind,
          subjectId: params.subjectId,
          scheduledAt: params.scheduledAt,
          scheduleSource: params.scheduleSource,
        );
  }
}

SchoolAssessment? schoolAssessmentForEntry(
  WidgetRef ref,
  CalendarEntry entry,
) {
  final key = schoolAssessmentLessonLookupKeyForEntry(entry);
  if (key == null) return null;
  return ref.watch(schoolAssessmentForLessonKeyProvider(key));
}

SchoolAssessment? schoolAssessmentPreviewForEntry(
  WidgetRef ref,
  CalendarEntry entry,
) {
  final key = schoolAssessmentLessonLookupKeyForEntry(entry);
  if (key == null) return null;
  return ref.watch(schoolAssessmentPreviewForLessonKeyProvider(key));
}
