import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_redirect_config.dart';

bool get _isAppleDesktopOrMobile {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

/// Registriert Deep Links für Supabase-Auth (nur iOS/macOS).
///
/// Nach Klick auf den Bestätigungslink öffnet die App und stellt die Session
/// aus der Redirect-URL wieder her.
Future<void> attachSupabaseAppleAuthDeepLinks() async {
  if (!_isAppleDesktopOrMobile) return;

  final appLinks = AppLinks();

  Future<void> handleUri(Uri? uri) async {
    if (uri == null) return;
    if (!uriLooksLikeSupabaseAuthCallback(uri)) return;
    try {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
    } catch (_, _) {
      // Intentionally ignored: callback processing should be best-effort.
    }
  }

  await handleUri(await appLinks.getInitialLink());
  appLinks.uriLinkStream.listen((uri) {
    unawaited(handleUri(uri));
  });
}
