import 'package:chronoapp/features/calendar/domain/filter/calendar_filter_defaults.dart';
import 'package:chronoapp/features/calendar/domain/filter/calendar_filters_state.dart';
import 'package:chronoapp/features/login/domain/models/guardian_child_link.dart';
import 'package:chronoapp/features/login/domain/models/profile_gate_data.dart';
import 'package:chronoapp/features/settings/data/models/profile_snapshot.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_child_profile_display.dart';
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

    final link = await _readActiveChildLink(db, userId, childId);
    final loaded = await _readChildSnapshot(db, childId);
    if (link == null && loaded == null) return null;
    if (link != null) {
      return guardianChildProfileSnapshot(link: link, loaded: loaded);
    }
    return loaded;
  }

  static Future<GuardianChildLink?> _readActiveChildLink(
    PowerSyncDatabase db,
    String guardianId,
    String childId,
  ) async {
    try {
      final row = await db.getOptional(
        '''
        SELECT
          gcl.id,
          gcl.guardian_id,
          gcl.child_id,
          gcl.status,
          gcl.created_at,
          gcl.responded_at,
          gcl.reminder_sent_at,
          cp.first_name AS child_first_name,
          cp.last_name AS child_last_name,
          cp.class_name AS child_class_name,
          cp.choir AS child_choir,
          cp.voice AS child_voice,
          cp.schooltrack AS child_schooltrack,
          cp.diet AS child_diet,
          gp.first_name AS guardian_first_name,
          gp.last_name AS guardian_last_name
        FROM $kGuardianChildLinksTable gcl
        LEFT JOIN $kProfilesTable cp ON cp.id = gcl.child_id
        LEFT JOIN $kProfilesTable gp ON gp.id = gcl.guardian_id
        WHERE gcl.guardian_id = ? AND gcl.child_id = ? AND gcl.status = 'confirmed'
        LIMIT 1
        ''',
        [guardianId, childId],
      );
      if (row == null) return null;
      return GuardianChildLink.fromRow(Map<String, dynamic>.from(row));
    } catch (_) {
      return null;
    }
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
