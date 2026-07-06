import 'dart:convert';

import 'package:chronoapp/core/push/push_notification_service.dart';
import 'package:chronoapp/core/widgets/app_toast.dart';

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';

import 'package:powersync/powersync.dart';

import 'package:supabase_flutter/supabase_flutter.dart';



import 'calendar_events_debug_log.dart';

import 'postgres_enum_array_codec.dart';

import 'powersync_config.dart';

import 'powersync_schema.dart';



/// Postgres/PostgREST-Codes: nicht per Retry lösbar (PowerSync-Demo-Pattern).

final List<RegExp> kPowerSyncFatalPostgrestCodes = [

  RegExp(r'^22...$'),

  RegExp(r'^23...$'),

  RegExp(r'^42501$'),

];



class CalendarUploadException implements Exception {

  CalendarUploadException(this.message);



  final String message;



  @override

  String toString() => message;

}



class BackendConnector extends PowerSyncBackendConnector {

  BackendConnector({required this.supabase});



  final SupabaseClient supabase;



  Future<void>? _refreshFuture;



  @override

  Future<PowerSyncCredentials?> fetchCredentials() async {

    final pending = _refreshFuture;

    if (pending != null) await pending;



    final session = supabase.auth.currentSession;

    if (session == null) return null;

    if (!isPowerSyncSyncEnabled()) return null;



    final expiresAt = session.expiresAt == null

        ? null

        : DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);



    return PowerSyncCredentials(

      endpoint: kPowerSyncUrl.trim(),

      token: session.accessToken,

      userId: session.user.id,

      expiresAt: expiresAt,

    );

  }



  @override

  void invalidateCredentials() {

    _refreshFuture = supabase.auth

        .refreshSession()

        .timeout(const Duration(seconds: 5))

        .then((_) => null, onError: (_) => null);

  }



  @override

  Future<void> uploadData(PowerSyncDatabase database) async {

    final transaction = await database.getNextCrudTransaction();

    if (transaction == null) return;



    if (kDebugMode) {

      debugPrint(

        '[CalendarSync] uploadData: ${transaction.crud.length} op(s)',

      );

    }



    try {

      for (final op in transaction.crud) {

        final reconciledId = await _applyCrudOp(op, database);

        if (reconciledId != null) {

          await _reconcileHomeworkContributionId(

            database: database,

            localId: op.id,

            serverId: reconciledId,

          );

        }

      }

      await transaction.complete();

      if (kDebugMode) {

        final queue = await database.getUploadQueueStats();

        debugPrint('[CalendarSync] upload complete, queue=${queue.count}');

      }

    } on PostgrestException catch (e) {

      final mustNotDropUpload = transaction.crud.any(

        (op) =>

            op.table == kCalendarEventsTable ||

            op.table == kCalendarSeriesTable ||

            op.table == kProfilesTable ||

            op.table == kHomeworkTasksTable ||

            op.table == kHomeworkContributionsTable ||

            op.table == kHomeworkPeerDismissalsTable ||

            op.table == kSchoolAssessmentsTable,

      );

      logCalendarEventUploadOp(

        UpdateType.patch,

        'upload_error',

        e.code ?? 'unknown',

        e.message,

      );

      if (mustNotDropUpload) {

        rethrow;

      }

      if (e.code != null &&

          kPowerSyncFatalPostgrestCodes.any((re) => re.hasMatch(e.code!))) {

        await transaction.complete();

      } else {

        rethrow;

      }

    } on CalendarUploadException {

      rethrow;

    }

  }



  Future<String?> _applyCrudOp(
    CrudEntry op,
    PowerSyncDatabase database,
  ) async {

    final table = supabase.from(op.table);



    switch (op.op) {

      case UpdateType.put:

        final data = Map<String, dynamic>.from(op.opData ?? {});

        _normalizeCalendarPayloadForUpload(op.table, data);

        data['id'] = op.id;

        logCalendarEventUploadOp(

          op.op,

          op.table,

          op.id,

          data['event_name'],

        );

        if (op.table == kHomeworkContributionsTable) {

          return _upsertHomeworkContribution(table, op, data);

        }

        final inserted = await table.upsert(data).select('id');

        _ensureRowsAffected(

          op: op,

          rows: inserted,

          action: 'upsert',

        );

        return null;

      case UpdateType.patch:

        final patch = Map<String, dynamic>.from(op.opData ?? {});

        _normalizeCalendarPayloadForUpload(op.table, patch);

        logCalendarEventUploadOp(op.op, op.table, op.id, patch);

        if (patch.isEmpty) {
          if (kDebugMode) {
            debugPrint(
              '[CalendarSync] skip empty patch ${op.table} id=${op.id}',
            );
          }
          return null;
        }

        final updated = await table.update(patch).eq('id', op.id).select('id');

        _ensureRowsAffected(

          op: op,

          rows: updated,

          action: 'update',

        );

        return null;

      case UpdateType.delete:

        logCalendarEventUploadOp(op.op, op.table, op.id, null);

        final deleted = await table.delete().eq('id', op.id).select('id');

        _ensureRowsAffected(

          op: op,

          rows: deleted,

          action: 'delete',

        );

        return null;

    }

  }



  Future<String?> _upsertHomeworkContribution(

    SupabaseQueryBuilder table,

    CrudEntry op,

    Map<String, dynamic> data,

  ) async {

    try {

      final rows = await table

          .upsert(

            data,

            onConflict:

                'profile_id,class_name,schooltrack,subject_id,lesson_date',

          )

          .select('id');

      _ensureRowsAffected(op: op, rows: rows, action: 'upsert');

      final serverId = rows.first['id'] as String;

      return serverId == op.id ? null : serverId;

    } on PostgrestException catch (e) {

      if (e.code != '23505') rethrow;

      return _patchHomeworkContributionByNaturalKey(table, op, data, e);

    }

  }



  Future<String?> _patchHomeworkContributionByNaturalKey(

    SupabaseQueryBuilder table,

    CrudEntry op,

    Map<String, dynamic> data,

    PostgrestException original,

  ) async {

    final schooltrack = data['schooltrack'];

    var query = table

        .select('id')

        .eq('profile_id', data['profile_id'] as String)

        .eq('class_name', data['class_name'] as String)

        .eq('subject_id', data['subject_id'] as String)

        .eq('lesson_date', data['lesson_date'] as String);



    if (schooltrack == null || '$schooltrack'.trim().isEmpty) {

      query = query.filter('schooltrack', 'is', null);

    } else {

      query = query.eq('schooltrack', schooltrack);

    }



    final existing = await query.maybeSingle();

    if (existing == null) throw original;



    final serverId = existing['id'] as String;

    final patch = Map<String, dynamic>.from(data)..remove('id');

    final updated = await table.update(patch).eq('id', serverId).select('id');

    _ensureRowsAffected(op: op, rows: updated, action: 'update');

    return serverId == op.id ? null : serverId;

  }



  Future<void> _reconcileHomeworkContributionId({

    required PowerSyncDatabase database,

    required String localId,

    required String serverId,

  }) async {

    if (localId == serverId) return;



    await database.writeTransaction((tx) async {

      final rows = await tx.getAll(

        'SELECT * FROM $kHomeworkContributionsTable WHERE id = ? LIMIT 1',

        [localId],

      );

      if (rows.isEmpty) return;



      final row = rows.first;

      await tx.execute(

        'DELETE FROM $kHomeworkContributionsTable WHERE id = ?',

        [localId],

      );

      await tx.execute(

        '''

        INSERT INTO $kHomeworkContributionsTable

          (id, profile_id, class_name, schooltrack, subject_id, lesson_date,

           fragments, fragment_hashes, created_at, updated_at)

        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)

        ON CONFLICT(id) DO UPDATE SET

          fragments = excluded.fragments,

          fragment_hashes = excluded.fragment_hashes,

          updated_at = excluded.updated_at

        ''',

        [

          serverId,

          row['profile_id'],

          row['class_name'],

          row['schooltrack'],

          row['subject_id'],

          row['lesson_date'],

          row['fragments'],

          row['fragment_hashes'],

          row['created_at'],

          row['updated_at'],

        ],

      );

      await tx.execute(

        '''

        UPDATE $kHomeworkTasksTable

        SET contribution_id = ?

        WHERE contribution_id = ?

        ''',

        [serverId, localId],

      );

    });

  }



  static void _normalizeCalendarPayloadForUpload(
    String table,
    Map<String, dynamic> data,
  ) {
    if (table == kCalendarEventsTable) {
      if (data.containsKey('choir')) {
        data['choir'] = PostgresEnumArrayCodec.toSupabaseArray(data['choir']);
      }
      if (data.containsKey('voices')) {
        data['voices'] = PostgresEnumArrayCodec.toSupabaseArray(data['voices']);
      }
      if (data.containsKey('image_paths')) {
        data['image_paths'] =
            PostgresEnumArrayCodec.toSupabaseArray(data['image_paths']);
      }
      return;
    }

    if (table == kCalendarSeriesTable) {
      if (data.containsKey('choir')) {
        data['choir'] = PostgresEnumArrayCodec.decodeFirstToken(
          data['choir']?.toString(),
        );
      }
      if (data.containsKey('voices')) {
        data['voices'] = PostgresEnumArrayCodec.toSupabaseArray(data['voices']);
      }
      return;
    }

    if (table == kProfilesTable && data.containsKey('calendar_preferences')) {
      final raw = data['calendar_preferences'];
      if (raw is String) {
        final trimmed = raw.trim();
        if (trimmed.isNotEmpty) {
          try {
            final decoded = jsonDecode(trimmed);
            if (decoded is Map<String, dynamic>) {
              data['calendar_preferences'] = decoded;
            }
          } catch (_) {
            // Unverändert lassen — Server antwortet mit Fehler.
          }
        }
      }
    }

    if (table == kHomeworkTasksTable || table == kHomeworkContributionsTable) {
      if (data.containsKey('fragments')) {
        data['fragments'] = _decodeJsonField(data['fragments']);
      }
      if (table == kHomeworkContributionsTable &&
          data.containsKey('fragment_hashes')) {
        data['fragment_hashes'] =
            PostgresEnumArrayCodec.toSupabaseArray(data['fragment_hashes']);
      }
      if (table == kHomeworkTasksTable && data.containsKey('is_completed')) {
        data['is_completed'] = data['is_completed'] == true ||
            data['is_completed'] == 1 ||
            data['is_completed'] == '1';
      }
      return;
    }

    if (table == kHomeworkSyntaxSuggestionsTable) {
      if (data.containsKey('aliases')) {
        data['aliases'] = PostgresEnumArrayCodec.toSupabaseArray(data['aliases']);
      }
      if (data.containsKey('is_global')) {
        data['is_global'] = data['is_global'] == true ||
            data['is_global'] == 1 ||
            data['is_global'] == '1';
      }
    }
  }

  static dynamic _decodeJsonField(dynamic raw) {
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return [];
      try {
        return jsonDecode(trimmed);
      } catch (_) {
        return raw;
      }
    }
    return raw;
  }

  void _ensureRowsAffected({

    required CrudEntry op,

    required List<Map<String, dynamic>> rows,

    required String action,

  }) {

    if (rows.isNotEmpty) return;

    throw CalendarUploadException(

      'Supabase-$action in ${op.table} für id=${op.id} hat 0 Zeilen betroffen. '

      'Häufige Ursache: RLS ohne Schreib-Policy für Admins (profiles.role = Admin). '

      'Siehe backend/ADMIN_CALENDAR_RLS.md.',

    );

  }



  static Future<void> logout(BuildContext context) async {

    try {

      await PushNotificationService().clearTokenOnLogout();

      await Supabase.instance.client.auth.signOut();

    } catch (error) {

      if (context.mounted) {

        showAppToast(

          context,

          'Fehler beim Abmelden: $error',

          kind: AppToastKind.error,

        );

      }

    }

  }

}

