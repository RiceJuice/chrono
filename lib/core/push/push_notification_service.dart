import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'fcm_token_repository.dart';

/// FCM-Token holen und in Supabase persistieren (nur mobile Plattformen).
class PushNotificationService {
  PushNotificationService({
    FirebaseMessaging? messaging,
    FcmTokenRepository? tokenRepository,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _tokenRepository = tokenRepository ?? FcmTokenRepository();

  final FirebaseMessaging _messaging;
  final FcmTokenRepository _tokenRepository;

  static bool get supportsPush =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> registerListeners() async {
    if (!supportsPush) return;

    _messaging.onTokenRefresh.listen((token) async {
      await _persistToken(token);
    });

    FirebaseMessaging.onMessage.listen((message) {
      if (kDebugMode) {
        debugPrint(
          '[FCM] foreground: ${message.notification?.title}',
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

  Future<void> clearTokenOnLogout() => _tokenRepository.clearToken();

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
