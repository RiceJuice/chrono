import 'dart:async';

import 'package:powersync/powersync.dart';

/// Zeigt, ob die lokale Tabelle Zeilen hat (unabhängig vom Kalenderfilter).
Future<void> logCalendarEventsLocalSnapshot(
  PowerSyncDatabase db, {
  String label = 'snapshot',
}) async {}

void scheduleCalendarEventsLocalSnapshots(PowerSyncDatabase db) {
  unawaited(Future<void>.value());
}

void attachCalendarEventsDebugLogs(PowerSyncDatabase db) {}

void logCalendarEventUploadOp(
  UpdateType op,
  String table,
  String id,
  Object? extra,
) {
  return;
}
