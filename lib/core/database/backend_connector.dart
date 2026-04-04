import 'package:flutter/foundation.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'calendar_events_debug_log.dart';
import 'powersync_config.dart';

/// Postgres/PostgREST-Codes: nicht per Retry lösbar (PowerSync-Demo-Pattern).
final List<RegExp> kPowerSyncFatalPostgrestCodes = [
  RegExp(r'^22...$'),
  RegExp(r'^23...$'),
  RegExp(r'^42501$'),
];

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

    CrudEntry? lastOp;
    try {
      for (final op in transaction.crud) {
        lastOp = op;
        final table = supabase.from(op.table);

        switch (op.op) {
          case UpdateType.put:
            final data = Map<String, dynamic>.from(op.opData ?? {});
            data['id'] = op.id;
            logCalendarEventUploadOp(
              op.op,
              op.table,
              op.id,
              data['title'],
            );
            await table.upsert(data);
          case UpdateType.patch:
            final patch = op.opData;
            logCalendarEventUploadOp(op.op, op.table, op.id, patch);
            if (patch != null && patch.isNotEmpty) {
              await table.update(patch).eq('id', op.id);
            }
          case UpdateType.delete:
            logCalendarEventUploadOp(op.op, op.table, op.id, null);
            await table.delete().eq('id', op.id);
        }
      }
      await transaction.complete();
    } on PostgrestException catch (e) {
      final code = e.code;
      if (code != null &&
          kPowerSyncFatalPostgrestCodes.any((re) => re.hasMatch(code))) {
        debugPrint(
          '[PowerSync→Supabase] Fataler Upload-Fehler, Transaktion verworfen: '
          '$lastOp → $e',
        );
        await transaction.complete();
      } else {
        rethrow;
      }
    }
  }
}
