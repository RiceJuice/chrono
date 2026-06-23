import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../features/calendar/live_activity/presentation/schedule_live_activity_coordinator.dart';
import '../../features/login/presentation/services/guardian_link_bootstrap.dart';
import 'push_device_repository.dart';

typedef GuardianLinkPushHandler = void Function(Map<String, String> data);

/// FCM-Token holen und in Supabase persistieren (nur mobile Plattformen).
class PushNotificationService {
  PushNotificationService({
    FirebaseMessaging? messaging,
    PushDeviceRepository? tokenRepository,
    GuardianLinkPushHandler? onGuardianLinkPush,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _tokenRepository = tokenRepository ?? PushDeviceRepository(),
        _onGuardianLinkPush =
            onGuardianLinkPush ?? GuardianLinkBootstrap.handlePushPayload;

  final FirebaseMessaging _messaging;
  final PushDeviceRepository _tokenRepository;
  final GuardianLinkPushHandler _onGuardianLinkPush;

  static bool get supportsPush =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> registerListeners() async {
    if (!supportsPush) return;

    _messaging.onTokenRefresh.listen((token) async {
      await _persistToken(token);
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _handleOpenedMessage(initial);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final data = _stringifyData(message.data);
    if (_handleGuardianLinkData(data)) return;
    if (data['type'] == 'schedule_live_activity') {
      unawaited(
        ScheduleLiveActivityCoordinator.instance?.handleFcmData(data),
      );
      return;
    }
    if (kDebugMode) {
      debugPrint('[FCM] foreground: ${message.notification?.title}');
    }
  }

  void _handleOpenedMessage(RemoteMessage message) {
    final data = _stringifyData(message.data);
    if (_handleGuardianLinkData(data)) return;
    if (data['type'] == 'schedule_live_activity') {
      unawaited(
        ScheduleLiveActivityCoordinator.instance?.handleFcmData(data),
      );
    }
  }

  bool _handleGuardianLinkData(Map<String, String> data) {
    final type = data['type'];
    if (type != 'guardian_link_request' && type != 'guardian_link_confirmed') {
      return false;
    }
    _onGuardianLinkPush(data);
    return true;
  }

  Map<String, String> _stringifyData(Map<String, dynamic> data) {
    return data.map((k, v) => MapEntry(k, v.toString()));
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
        debugPrint(
          '[FCM] permission not granted: ${settings.authorizationStatus}',
        );
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
