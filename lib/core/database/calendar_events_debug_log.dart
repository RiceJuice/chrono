import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:powersync/powersync.dart';

import 'powersync_schema.dart';

const String _tag = '[CalendarEvents]';

/// Zeigt, ob die lokale Tabelle Zeilen hat (unabhängig vom Kalenderfilter).
Future<void> logCalendarEventsLocalSnapshot(
  PowerSyncDatabase db, {
  String label = 'snapshot',
}) async {
  if (!kDebugMode) return;
  try {
    final now = DateTime.now();
    debugPrint(
      '$_tag[debug][$label] Gerät: ${now.timeZoneName} offset=${now.timeZoneOffset}',
    );
    final row = await db.get(
      'SELECT COUNT(*) AS c FROM $kCalendarEventsTable',
    );
    final raw = row['c'];
    final count = raw is int ? raw : int.parse(raw.toString());
    debugPrint('$_tag[debug][$label] COUNT(*) = $count');
    if (count > 0) {
      final samples = await db.getAll(
        'SELECT id, start_time, title FROM $kCalendarEventsTable ORDER BY start_time LIMIT 15',
      );
      for (final r in samples) {
        debugPrint(
          '$_tag[debug][$label] Zeile id=${r['id']} start_time=${r['start_time']} title=${r['title']}',
        );
      }
    }
  } catch (e) {
    debugPrint('$_tag[debug][$label] Fehler: $e');
  }
}

void scheduleCalendarEventsLocalSnapshots(PowerSyncDatabase db) {
  if (!kDebugMode) return;
  unawaited(logCalendarEventsLocalSnapshot(db, label: 'direkt nach open'));
  unawaited(
    Future<void>.delayed(const Duration(seconds: 3), () {
      return logCalendarEventsLocalSnapshot(db, label: '+3s');
    }),
  );
  unawaited(
    Future<void>.delayed(const Duration(seconds: 10), () {
      return logCalendarEventsLocalSnapshot(db, label: '+10s (nach typ. Sync)');
    }),
  );
}

void attachCalendarEventsDebugLogs(PowerSyncDatabase db) {
  if (!kDebugMode) return;

  db.getCrudTransactions().listen((CrudTransaction tx) {
    for (final op in tx.crud) {
      if (op.table != kCalendarEventsTable) continue;
      final title = op.opData?['title'];
      switch (op.op) {
        case UpdateType.put:
          debugPrint(
            '$_tag[lokal→Upload-Queue] PUT id=${op.id} title=${title ?? "?"}',
          );
        case UpdateType.patch:
          debugPrint(
            '$_tag[lokal→Upload-Queue] PATCH id=${op.id} data=${op.opData}',
          );
        case UpdateType.delete:
          debugPrint('$_tag[lokal→Upload-Queue] DELETE id=${op.id}');
      }
    }
  });

  db.onChange(const [kCalendarEventsTable]).listen((_) {
    debugPrint(
      '$_tag[sqlite] Tabelle $kCalendarEventsTable geändert (lokal oder Sync)',
    );
  });
}

void logCalendarEventUploadOp(
  UpdateType op,
  String table,
  String id,
  Object? extra,
) {
  if (!kDebugMode) return;
  if (table != kCalendarEventsTable) return;
  final suffix = extra != null ? ' $extra' : '';
  switch (op) {
    case UpdateType.put:
      debugPrint('$_tag[PowerSync→Supabase] UPSERT id=$id$suffix');
    case UpdateType.patch:
      debugPrint('$_tag[PowerSync→Supabase] PATCH id=$id$suffix');
    case UpdateType.delete:
      debugPrint('$_tag[PowerSync→Supabase] DELETE id=$id');
  }
}
