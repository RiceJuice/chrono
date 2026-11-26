import 'package:chronoapp/core/database/school_subject_choices_cache.dart';
import 'dart:async';
import 'package:chronoapp/core/database/school_subject_choices.dart';

import 'package:powersync/powersync.dart';
import 'package:sqlite3/common.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/powersync_schema.dart';
import 'models/profile_snapshot.dart';

class SettingsProfileRepositoryException implements Exception {
  SettingsProfileRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _ProfileRowBundle {
  const _ProfileRowBundle({required this.snapshot, this.updatedAt});

  final ProfileSnapshot snapshot;
  final DateTime? updatedAt;
}

/// Liest das Profil aus PowerSync und ergänzt bei Bedarf per Supabase, solange
/// der lokale Sync nach Onboarding/Profil-Updates noch hinterherhinkt.
class SettingsProfileRepository {
  SettingsProfileRepository(this._db, {SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  static const Duration _remoteFetchTimeout = Duration(seconds: 2);

  final PowerSyncDatabase _db;
  final SupabaseClient _supabase;

  _ProfileRowBundle? _cachedRemote;

  Stream<ProfileSnapshot?> watchProfileByUserId(String userId) async* {
    _cachedRemote = null;

    final rebuilds = StreamController<Object?>.broadcast();
    DateTime? lastHandledSyncAt;

    final localSub = _watchLocalBundles(userId).listen((_) {
      if (!rebuilds.isClosed) rebuilds.add(null);
    });
    final syncSub = _db.statusStream.listen((status) {
      final syncedAt = status.lastSyncedAt;
      if (syncedAt == null || syncedAt == lastHandledSyncAt) return;
      lastHandledSyncAt = syncedAt;
      if (!rebuilds.isClosed) rebuilds.add(null);
    });

    rebuilds.add(null);

    try {
      await for (final _ in rebuilds.stream) {
        final local = await _readCurrentLocalBundle(userId);
        if (_shouldFetchRemote(local)) {
          _cachedRemote = await _fetchRemoteBundle(userId);
        }
        yield _mergeBundles(local, _cachedRemote)?.snapshot;
      }
    } finally {
      await localSub.cancel();
      await syncSub.cancel();
      await rebuilds.close();
    }
  }

  Future<_ProfileRowBundle?> _readCurrentLocalBundle(String userId) async {
    try {
      final rows = await _db.getAll(
        '''
        SELECT first_name, last_name, class_name, schooltrack, arts_subject, language_subject, timetable_subject_choices, voice, role, choir, diet,
               updated_at
        FROM $kProfilesTable
        WHERE id = ?
        LIMIT 1
        ''',
        [userId],
      );
      if (rows.isEmpty) return null;
      return _mapRowBundle(
        await SchoolSubjectChoicesCache.supplement(
          userId,
          Map<String, dynamic>.from(rows.first),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Stream<_ProfileRowBundle?> _watchLocalBundles(String userId) {
    return _db
        .watch(
          '''
          SELECT first_name, last_name, class_name, schooltrack, arts_subject, language_subject, timetable_subject_choices, voice, role, choir, diet,
                 updated_at
          FROM $kProfilesTable
          WHERE id = ?
          LIMIT 1
          ''',
          parameters: [userId],
          triggerOnTables: const {kProfilesTable},
        )
        .map(_mapFirstRowBundleOrNull);
  }

  bool _shouldFetchRemote(_ProfileRowBundle? local) {
    final cached = _cachedRemote;
    if (cached == null || local == null) return true;
    final localUpdated = local.updatedAt;
    final cachedUpdated = cached.updatedAt;
    return _isProfileEmpty(local.snapshot) ||
        (localUpdated != null &&
            (cachedUpdated == null || localUpdated.isAfter(cachedUpdated)));
  }

  Future<_ProfileRowBundle?> _fetchRemoteBundle(String userId) async {
    try {
      final row = await _supabase
          .from('profiles')
          .select(
            'first_name, last_name, class_name, schooltrack, arts_subject, language_subject, timetable_subject_choices, voice, role, choir, diet, updated_at',
          )
          .eq('id', userId)
          .maybeSingle()
          .timeout(_remoteFetchTimeout);
      if (row == null) return null;
      await SchoolSubjectChoicesCache.save(
        userId,
        Map<String, dynamic>.from(row),
      );
      return _mapRowBundle(Map<String, dynamic>.from(row));
    } catch (_) {
      return _cachedRemote;
    }
  }

  _ProfileRowBundle? _mapFirstRowBundleOrNull(ResultSet rows) {
    if (rows.isEmpty) return null;
    return _mapRowBundle(Map<String, dynamic>.from(rows.first));
  }

  _ProfileRowBundle? _mapRowBundle(Map<String, dynamic> row) {
    final snapshot = ProfileSnapshot(
      firstName: _asString(row['first_name']),
      lastName: _asString(row['last_name']),
      className: _asString(row['class_name']),
      schoolTrack: _asString(row['schooltrack']),
      artsSubject: _asString(row['arts_subject']),
      languageSubject: _asString(row['language_subject']),
      timetableChoices: decodeSchoolSubjectChoices(
        row['timetable_subject_choices'],
      ),
      voice: _asString(row['voice']),
      role: _asString(row['role']),
      choir: _asString(row['choir']),
      diet: _asString(row['diet']),
    );
    if (_isProfileEmpty(snapshot)) return null;
    return _ProfileRowBundle(
      snapshot: snapshot,
      updatedAt: _asDateTime(row['updated_at']),
    );
  }

  _ProfileRowBundle? _mergeBundles(
    _ProfileRowBundle? local,
    _ProfileRowBundle? remote,
  ) {
    if (local == null) return remote;
    if (remote == null) return local;

    final localUpdated = local.updatedAt;
    final remoteUpdated = remote.updatedAt;
    final mergedUpdated = localUpdated != null && remoteUpdated != null
        ? (localUpdated.isAfter(remoteUpdated) ? localUpdated : remoteUpdated)
        : (localUpdated ?? remoteUpdated);

    return _ProfileRowBundle(
      snapshot:
          remoteUpdated != null &&
              (localUpdated == null || remoteUpdated.isAfter(localUpdated))
          ? remote.snapshot
          : _coalesceSnapshots(local.snapshot, remote.snapshot),
      updatedAt: mergedUpdated,
    );
  }

  ProfileSnapshot _coalesceSnapshots(
    ProfileSnapshot local,
    ProfileSnapshot remote,
  ) {
    return ProfileSnapshot(
      firstName: _coalesceField(local.firstName, remote.firstName),
      lastName: _coalesceField(local.lastName, remote.lastName),
      className: _coalesceField(local.className, remote.className),
      schoolTrack: _coalesceField(local.schoolTrack, remote.schoolTrack),
      artsSubject: _coalesceField(local.artsSubject, remote.artsSubject),
      languageSubject: _coalesceField(
        local.languageSubject,
        remote.languageSubject,
      ),
      timetableChoices: local.timetableChoices.isNotEmpty
          ? local.timetableChoices
          : remote.timetableChoices,
      voice: _coalesceField(local.voice, remote.voice),
      role: _coalesceField(local.role, remote.role),
      choir: _coalesceField(local.choir, remote.choir),
      diet: _coalesceField(local.diet, remote.diet),
    );
  }

  String? _coalesceField(String? local, String? remote) {
    if ((local ?? '').trim().isNotEmpty) return local!.trim();
    if ((remote ?? '').trim().isNotEmpty) return remote!.trim();
    return null;
  }

  bool _isProfileEmpty(ProfileSnapshot profile) {
    return [
      profile.firstName,
      profile.lastName,
      profile.className,
      profile.schoolTrack,
      profile.voice,
      profile.role,
      profile.choir,
      profile.diet,
    ].every((value) => (value ?? '').trim().isEmpty);
  }

  String? _asString(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  DateTime? _asDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  /// Aktualisiert Kalender-Standardwerte eines verknüpften Kindes (nur bestätigte Links).
  Future<void> updateLinkedChildCalendarDefaults({
    required String childId,
    String? className,
    String? schoolTrack,
    String? voice,
    String? diet,
    String? choir,
    String? artsSubject,
    String? languageSubject,
  }) async {
    if (childId.trim().isEmpty) {
      throw SettingsProfileRepositoryException('Kein Kind ausgewählt.');
    }

    final updates = <String, dynamic>{};
    if (className != null) updates['class_name'] = className;
    if (schoolTrack != null) updates['schooltrack'] = schoolTrack;
    if (voice != null) updates['voice'] = voice;
    if (diet != null) updates['diet'] = diet;
    if (choir != null) updates['choir'] = choir;

    if (artsSubject != null) updates['arts_subject'] = artsSubject;
    if (languageSubject != null) updates['language_subject'] = languageSubject;
    if (updates.isEmpty) return;

    try {
      if (artsSubject != null || languageSubject != null) {
        final existing = await _supabase
            .from('profiles')
            .select('class_name,schooltrack,timetable_subject_choices')
            .eq('id', childId)
            .single();
        updates['timetable_subject_choices'] = updateSchoolSubjectChoices(
          existing: decodeSchoolSubjectChoices(
            existing['timetable_subject_choices'],
          ),
          className: className ?? existing['class_name']?.toString(),
          schoolTrack: schoolTrack ?? existing['schooltrack']?.toString(),
          artsSubject: artsSubject,
          languageSubject: languageSubject,
        );
      }
      final updatedRows = await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', childId)
          .select('id');
      if (updatedRows.isNotEmpty) return;
      throw SettingsProfileRepositoryException(
        'Änderung konnte nicht gespeichert werden. Bitte erneut versuchen.',
      );
    } catch (e) {
      if (e is SettingsProfileRepositoryException) rethrow;
      throw SettingsProfileRepositoryException(
        'Änderung konnte nicht gespeichert werden. Bitte erneut versuchen.',
      );
    }
  }
}
