import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import '../../features/calendar/live_activity/presentation/schedule_live_activity_coordinator.dart';

/// Muss Top-Level-Funktion sein (Firebase-Anforderung).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!DefaultFirebaseOptions.isConfigured) return;

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final data = message.data;
  if (data['type'] == 'schedule_live_activity') {
    await ScheduleLiveActivityCoordinator.instance?.handleFcmData(
      data.map((k, v) => MapEntry(k, v.toString())),
    );
    return;
  }

  if (kDebugMode) {
    debugPrint(
      '[FCM] background message: ${message.notification?.title}',
    );
  }
}
