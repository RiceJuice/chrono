import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:powersync/powersync.dart';

const String _tag = 'CalendarSync';

/// Zeigt, ob die lokale Tabelle Zeilen hat (unabhängig vom Kalenderfilter).
Future<void> logCalendarEventsLocalSnapshot(
  PowerSyncDatabase db, {
  String label = 'snapshot',
}) async {
  if (!kDebugMode) return;
  try {
    final events = await db.getAll(
      'SELECT COUNT(*) AS c FROM calendar_events',
    );
    final series = await db.getAll(
      'SELECT COUNT(*) AS c FROM calendar_series',
    );
    final queue = await db.getUploadQueueStats();
    _log(
      '$label: events=${events.first['c']}, series=${series.first['c']}, '
      'uploadQueue=${queue.count}',
    );
  } catch (e, st) {
    _log('$label failed: $e', stackTrace: st);
  }
}

void scheduleCalendarEventsLocalSnapshots(PowerSyncDatabase db) {
  if (!kDebugMode) return;
  unawaited(logCalendarEventsLocalSnapshot(db, label: 'startup'));
}

void attachCalendarEventsDebugLogs(PowerSyncDatabase db) {
  if (!kDebugMode) return;

  db.statusStream.listen((status) {
    if (status.uploading) {
      _log('uploading…');
    }
    if (status.uploadError != null) {
      _log('uploadError: ${status.uploadError}', level: 1000);
    }
    if (status.downloadError != null) {
      _log('downloadError: ${status.downloadError}', level: 1000);
    }
  });
}

void logCalendarEventUploadOp(
  UpdateType op,
  String table,
  String id,
  Object? extra,
) {
  if (!kDebugMode) return;
  _log('upload ${op.name} $table id=$id extra=$extra');
}

void logCalendarEventWriteResult({
  required String action,
  required String table,
  required String id,
  int? uploadQueueCount,
}) {
  if (!kDebugMode) return;
  _log(
    'local $action $table id=$id queue=$uploadQueueCount',
  );
}

void _log(String message, {int level = 500, StackTrace? stackTrace}) {
  developer.log(message, name: _tag, level: level, stackTrace: stackTrace);
  debugPrint('[$_tag] $message');
}
