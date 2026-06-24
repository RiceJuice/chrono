import 'package:chronoapp/features/calendar/domain/filter/calendar_filter_defaults.dart';
import 'package:chronoapp/features/calendar/domain/filter/calendar_filters_state.dart';
import 'package:chronoapp/features/login/domain/models/profile_gate_data.dart';
import 'package:chronoapp/features/settings/data/models/profile_snapshot.dart';
import 'package:powersync/powersync.dart';

import '../../../core/database/powersync_schema.dart';

/// Vorberechneter Kalender-Filter vor dem Verlassen des Ladescreens.
class CalendarFilterStartupState {
  CalendarFilterStartupState._();

  static CalendarFiltersState? _bootstrapped;

  static void preload({
    required ProfileGateData gateData,
    String? diet,
    ProfileSnapshot? childProfile,
  }) {
    if (!gateData.hasSession) return;

    if (gateData.hasConfirmedGuardianLink) {
      if (childProfile == null) return;
      _bootstrapped = calendarFiltersStateFromProfileFields(
        choir: childProfile.choir,
        voice: childProfile.voice,
        className: childProfile.className,
        schoolTrack: childProfile.schoolTrack,
        diet: childProfile.diet ?? diet,
      );
      return;
    }

    _bootstrapped = calendarFiltersStateFromProfileFields(
      choir: gateData.choir,
      voice: gateData.voice,
      className: gateData.className,
      schoolTrack: gateData.schoolTrack,
      diet: diet,
    );
  }

  static Future<ProfileSnapshot?> loadChildProfileForStartup({
    required PowerSyncDatabase db,
    required ProfileGateData gateData,
    required String userId,
  }) async {
    if (!gateData.hasConfirmedGuardianLink) return null;
    if (!gateData.hasConfirmedGuardianLink) return null;

    var childId = gateData.activeChildId;
    if (childId == null || childId.isEmpty) {
      final row = await db.getOptional(
        '''
        SELECT child_id FROM $kGuardianChildLinksTable
        WHERE guardian_id = ? AND status = 'confirmed'
        ORDER BY created_at ASC
        LIMIT 1
        ''',
        [userId],
      );
      childId = row?['child_id']?.toString();
      if (childId == null || childId.isEmpty) return null;
    }

    return _readChildSnapshot(db, childId);
  }

  static Future<ProfileSnapshot?> _readChildSnapshot(
    PowerSyncDatabase db,
    String childId,
  ) async {
    try {
      final row = await db.getOptional(
        '''
        SELECT first_name, last_name, class_name, schooltrack, voice, role, choir, diet
        FROM $kProfilesTable
        WHERE id = ?
        LIMIT 1
        ''',
        [childId],
      );
      if (row == null) return null;
      return ProfileSnapshot(
        firstName: row['first_name']?.toString(),
        lastName: row['last_name']?.toString(),
        className: row['class_name']?.toString(),
        schoolTrack: row['schooltrack']?.toString(),
        voice: row['voice']?.toString(),
        role: row['role']?.toString(),
        choir: row['choir']?.toString(),
        diet: row['diet']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  static CalendarFiltersState? consume() {
    final bootstrapped = _bootstrapped;
    _bootstrapped = null;
    return bootstrapped;
  }

  static void reset() {
    _bootstrapped = null;
  }
}
