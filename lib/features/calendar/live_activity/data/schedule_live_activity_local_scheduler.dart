import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/time/app_date_time.dart';

typedef ScheduleLiveActivityNotificationHandler = Future<void> Function(
  String payload,
);

/// Plant lokale Notifications für Ablaufplan-Segmentstarts (heute + morgen).
class ScheduleLiveActivityLocalScheduler {
  ScheduleLiveActivityLocalScheduler({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String channelId = 'schedule_live_activity';
  static const String channelName = 'Ablaufplan';
  static const String payloadType = 'schedule_live_activity_local';

  final FlutterLocalNotificationsPlugin _plugin;
  ScheduleLiveActivityNotificationHandler? _onPayload;
  bool _initialized = false;

  static int notificationIdFor(String eventId, String scheduleId) {
    return Object.hash(eventId, scheduleId) & 0x7fffffff;
  }

  Future<void> init({
    required ScheduleLiveActivityNotificationHandler onPayload,
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
          scheduleLiveActivityNotificationTapBackground,
    );

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              channelId,
              channelName,
              description: 'Startet die Ablaufplan-Live-Activity zur Segmentzeit',
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

  Future<void> rescheduleSegments({
    required List<({String eventId, String scheduleId, DateTime start})>
        segments,
  }) async {
    if (!_initialized) return;

    await _plugin.cancelAll();

    final now = DateTime.now();
    final rangeEnd = AppDateTime.addLocalCalendarDays(
      AppDateTime.localDay(now),
      2,
    );

    for (final segment in segments) {
      final localStart = AppDateTime.toLocal(segment.start);
      if (!localStart.isAfter(now)) continue;
      if (!localStart.isBefore(rangeEnd)) continue;

      final tzTime = tz.TZDateTime.from(localStart, tz.local);
      final id = notificationIdFor(segment.eventId, segment.scheduleId);
      final payload = '${segment.eventId}|${segment.scheduleId}';

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
          debugPrint('[LiveActivity] schedule failed: $e\n$st');
        }
      }
    }
  }
}

@pragma('vm:entry-point')
void scheduleLiveActivityNotificationTapBackground(NotificationResponse response) {
  // Background tap — Coordinator wird beim nächsten App-Start synchronisiert.
  if (kDebugMode) {
    debugPrint('[LiveActivity] background notification: ${response.payload}');
  }
}
