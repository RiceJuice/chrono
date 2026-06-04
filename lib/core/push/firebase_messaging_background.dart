import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Muss Top-Level-Funktion sein (Firebase-Anforderung).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint(
      '[FCM] background message: ${message.notification?.title}',
    );
  }
}
