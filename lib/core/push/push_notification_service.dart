import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../features/calendar/live_activity/presentation/schedule_live_activity_coordinator.dart';
import 'push_device_repository.dart';

/// FCM-Token holen und in Supabase persistieren (nur mobile Plattformen).
class PushNotificationService {
  PushNotificationService({
    FirebaseMessaging? messaging,
    PushDeviceRepository? tokenRepository,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _tokenRepository = tokenRepository ?? PushDeviceRepository();

  final FirebaseMessaging _messaging;
  final PushDeviceRepository _tokenRepository;

  static bool get supportsPush =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> registerListeners() async {
    if (!supportsPush) return;

    _messaging.onTokenRefresh.listen((token) async {
      await _persistToken(token);
    });

    FirebaseMessaging.onMessage.listen((message) {
      final data = message.data;
      if (data['type'] == 'schedule_live_activity') {
        unawaited(
          ScheduleLiveActivityCoordinator.instance?.handleFcmData(
            data.map((k, v) => MapEntry(k, v.toString())),
          ),
        );
        return;
      }
      if (kDebugMode) {
        debugPrint(
          '[FCM] foreground: ${message.notification?.title}',
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final data = message.data;
      if (data['type'] == 'schedule_live_activity') {
        unawaited(
          ScheduleLiveActivityCoordinator.instance?.handleFcmData(
            data.map((k, v) => MapEntry(k, v.toString())),
          ),
        );
      }
    });
  }

  Future<void> syncTokenForCurrentUser() async {
    if (!supportsPush) return;

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final authorized = settings.authorizationStatus ==
            AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (!authorized) {
      if (kDebugMode) {
        debugPrint('[FCM] permission not granted: ${settings.authorizationStatus}');
      }
      return;
    }

    if (Platform.isIOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    await _persistToken(token);
  }

  Future<void> clearTokenOnLogout() =>
      _tokenRepository.clearTokenForCurrentDevice();

  Future<void> _persistToken(String token) async {
    try {
      await _tokenRepository.saveToken(token);
      if (kDebugMode) {
        debugPrint('[FCM] token saved (${token.length} chars)');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[FCM] token save failed: $e\n$st');
      }
    }
  }
}
