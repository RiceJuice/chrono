import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:powersync/powersync.dart';

import '../../../core/database/powersync_schema.dart';
import 'calendar_preferences_codec.dart';
import 'subject_color_codec.dart';

class ProfileCalendarPreferencesRepository {
  ProfileCalendarPreferencesRepository(this._db);

  final PowerSyncDatabase _db;

  Stream<bool> watchShowMealImages(String userId) {
    return _db
        .watch(
          '''
          SELECT calendar_preferences
          FROM $kProfilesTable
          WHERE id = ?
          LIMIT 1
          ''',
          parameters: [userId],
          triggerOnTables: const {kProfilesTable},
        )
        .map((rows) {
          if (rows.isEmpty) return true;
          return CalendarPreferencesCodec.decodeShowMealImages(
            rows.first['calendar_preferences'],
          );
        });
  }

  Future<void> setShowMealImages({
    required String userId,
    required bool enabled,
  }) async {
    await _db.writeTransaction((tx) async {
      final rows = await tx.getAll(
        '''
        SELECT calendar_preferences
        FROM $kProfilesTable
        WHERE id = ?
        LIMIT 1
        ''',
        [userId],
      );
      if (rows.isEmpty) {
        throw StateError('Profil nicht gefunden.');
      }

      final existing = rows.first['calendar_preferences'];
      final encoded = CalendarPreferencesCodec.encodeShowMealImages(
        existingPreferences: existing,
        enabled: enabled,
      );
      if (_storedPreferencesEqual(existing, encoded)) return;

      await tx.execute(
        '''
        UPDATE $kProfilesTable
        SET calendar_preferences = ?
        WHERE id = ?
        ''',
        [encoded, userId],
      );
    });
  }

  Stream<bool> watchEventChangeNotifications(String userId) {
    return _db
        .watch(
          '''
          SELECT calendar_preferences
          FROM $kProfilesTable
          WHERE id = ?
          LIMIT 1
          ''',
          parameters: [userId],
          triggerOnTables: const {kProfilesTable},
        )
        .map((rows) {
          if (rows.isEmpty) return true;
          return CalendarPreferencesCodec.decodeEventChangeNotifications(
            rows.first['calendar_preferences'],
          );
        });
  }

  Future<void> setEventChangeNotifications({
    required String userId,
    required bool enabled,
  }) async {
    await _db.writeTransaction((tx) async {
      final rows = await tx.getAll(
        '''
        SELECT calendar_preferences
        FROM $kProfilesTable
        WHERE id = ?
        LIMIT 1
        ''',
        [userId],
      );
      if (rows.isEmpty) {
        throw StateError('Profil nicht gefunden.');
      }

      final existing = rows.first['calendar_preferences'];
      final encoded = CalendarPreferencesCodec.encodeEventChangeNotifications(
        existingPreferences: existing,
        enabled: enabled,
      );
      if (_storedPreferencesEqual(existing, encoded)) return;

      await tx.execute(
        '''
        UPDATE $kProfilesTable
        SET calendar_preferences = ?
        WHERE id = ?
        ''',
        [encoded, userId],
      );
    });
  }

  Stream<Map<String, Color>> watchSubjectAccentOverrides(String userId) {
    return _db
        .watch(
          '''
          SELECT calendar_preferences
          FROM $kProfilesTable
          WHERE id = ?
          LIMIT 1
          ''',
          parameters: [userId],
          triggerOnTables: const {kProfilesTable},
        )
        .map((rows) {
          if (rows.isEmpty) return const <String, Color>{};
          return CalendarPreferencesCodec.decodeSubjectAccents(
            rows.first['calendar_preferences'],
          );
        });
  }

  Future<void> setSubjectAccent({
    required String userId,
    required String subjectId,
    required Color color,
  }) async {
    await _db.writeTransaction((tx) async {
      final rows = await tx.getAll(
        '''
        SELECT calendar_preferences
        FROM $kProfilesTable
        WHERE id = ?
        LIMIT 1
        ''',
        [userId],
      );
      if (rows.isEmpty) {
        throw StateError('Profil nicht gefunden.');
      }

      final existing = rows.first['calendar_preferences'];
      final merged = CalendarPreferencesCodec.mergeSubjectAccent(
        existingPreferences: existing,
        subjectId: subjectId,
        color: color,
      );
      if (_storedPreferencesEqual(existing, merged)) return;

      await tx.execute(
        '''
        UPDATE $kProfilesTable
        SET calendar_preferences = ?
        WHERE id = ?
        ''',
        [merged, userId],
      );
    });
  }

  Future<void> clearSubjectAccent({
    required String userId,
    required String subjectId,
  }) async {
    await _db.writeTransaction((tx) async {
      final rows = await tx.getAll(
        '''
        SELECT calendar_preferences
        FROM $kProfilesTable
        WHERE id = ?
        LIMIT 1
        ''',
        [userId],
      );
      if (rows.isEmpty) return;

      final current = CalendarPreferencesCodec.decodeSubjectAccents(
        rows.first['calendar_preferences'],
      );
      if (!current.containsKey(subjectId)) return;

      final next = Map<String, Color>.from(current)..remove(subjectId);
      final existing = rows.first['calendar_preferences'];
      final encoded = CalendarPreferencesCodec.encodeRootWithSubjectAccents(
        existingPreferences: existing,
        subjectAccents: next,
      );
      if (_storedPreferencesEqual(existing, encoded)) return;

      await tx.execute(
        '''
        UPDATE $kProfilesTable
        SET calendar_preferences = ?
        WHERE id = ?
        ''',
        [encoded, userId],
      );
    });
  }

  /// Vermeidet No-Op-UPDATEs (leere PowerSync-Patches).
  static bool _storedPreferencesEqual(Object? stored, String encoded) {
    final a = CalendarPreferencesCodec.decodeRoot(stored);
    final b = CalendarPreferencesCodec.decodeRoot(encoded);
    return jsonEncode(a) == jsonEncode(b);
  }

  /// Hilfsmethode für Tests und künftige UI — validiert Hex vor dem Speichern.
  static String formatColorForStorage(Color color) =>
      SubjectColorCodec.toHex(color);
}
