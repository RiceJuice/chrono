import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/time/app_date_time.dart';

typedef TimetableLiveActivityNotificationHandler = Future<void> Function(
  String payload,
);

/// Plant lokale Notifications für Stundenplan-Start (15 min vor erster Stunde).
class TimetableLiveActivityLocalScheduler {
  TimetableLiveActivityLocalScheduler({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String channelId = 'timetable_live_activity';
  static const String channelName = 'Stundenplan';
  static const String endPayloadMarker = 'end';

  final FlutterLocalNotificationsPlugin _plugin;
  TimetableLiveActivityNotificationHandler? _onPayload;
  bool _initialized = false;

  static int notificationIdForStart(String dayDateKey) {
    return Object.hash('timetable_start', dayDateKey) & 0x7fffffff;
  }

  static int notificationIdForDayEnd(String dayDateKey) {
    return Object.hash('timetable_day_end', dayDateKey) & 0x7fffffff;
  }

  Future<void> init({
    required TimetableLiveActivityNotificationHandler onPayload,
  }) async {
    _onPayload = onPayload;
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Europe/Berlin'));
    } catch (_) {
      tz.setLocalLocation(tz.local);
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          timetableLiveActivityNotificationTapBackground,
    );

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              channelId,
              channelName,
              description:
                  'Startet die Stundenplan-Live-Activity vor Unterrichtsbeginn',
              importance: Importance.low,
              playSound: false,
            ),
          );
    }

    _initialized = true;
  }

  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    unawaited(_onPayload?.call(payload));
  }

  Future<void> reschedule({
    required List<({String dayDateKey, DateTime start})> starts,
    required List<({String dayDateKey, DateTime end})> ends,
  }) async {
    if (!_initialized) return;

    await _plugin.cancelAll();

    final now = DateTime.now();
    final rangeEnd = AppDateTime.addLocalCalendarDays(
      AppDateTime.localDay(now),
      2,
    );

    for (final entry in starts) {
      final localStart = AppDateTime.toLocal(entry.start);
      if (!localStart.isAfter(now)) continue;
      if (!localStart.isBefore(rangeEnd)) continue;

      await _schedule(
        id: notificationIdForStart(entry.dayDateKey),
        at: localStart,
        payload: '${entry.dayDateKey}|start',
      );
    }

    for (final entry in ends) {
      final localEnd = AppDateTime.toLocal(entry.end);
      if (!localEnd.isAfter(now)) continue;
      if (!localEnd.isBefore(rangeEnd)) continue;

      await _schedule(
        id: notificationIdForDayEnd(entry.dayDateKey),
        at: localEnd,
        payload: '${entry.dayDateKey}|$endPayloadMarker',
      );
    }
  }

  Future<void> _schedule({
    required int id,
    required DateTime at,
    required String payload,
  }) async {
    final tzTime = tz.TZDateTime.from(at, tz.local);
    try {
      await _plugin.zonedSchedule(
        id,
        null,
        null,
        tzTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            importance: Importance.low,
            priority: Priority.low,
            playSound: false,
            silent: true,
            channelShowBadge: false,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: false,
            presentSound: false,
            presentBadge: false,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[TimetableLiveActivity] schedule failed: $e\n$st');
      }
    }
  }
}

@pragma('vm:entry-point')
void timetableLiveActivityNotificationTapBackground(
  NotificationResponse response,
) {
  if (kDebugMode) {
    debugPrint(
      '[TimetableLiveActivity] background notification: ${response.payload}',
    );
  }
}
