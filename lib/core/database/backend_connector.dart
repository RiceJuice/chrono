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

        await _applyCrudOp(op);

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

            op.table == kHomeworkContributionsTable,

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



  Future<void> _applyCrudOp(CrudEntry op) async {

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

        final inserted = await table.upsert(data).select('id');

        _ensureRowsAffected(

          op: op,

          rows: inserted,

          action: 'upsert',

        );

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
          return;
        }

        final updated = await table.update(patch).eq('id', op.id).select('id');

        _ensureRowsAffected(

          op: op,

          rows: updated,

          action: 'update',

        );

      case UpdateType.delete:

        logCalendarEventUploadOp(op.op, op.table, op.id, null);

        final deleted = await table.delete().eq('id', op.id).select('id');

        _ensureRowsAffected(

          op: op,

          rows: deleted,

          action: 'delete',

        );

    }

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

