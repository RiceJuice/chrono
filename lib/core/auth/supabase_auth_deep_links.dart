import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_redirect_config.dart';

bool get _isMobileAuthDeepLinkPlatform {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

/// Zusätzlicher Deep-Link-Listener für Supabase-Auth-Callbacks.
///
/// Ergänzt den eingebauten Observer von `supabase_flutter` (Initial-URI wird
/// dort bereits verarbeitet). Relevant für E-Mail-Bestätigung und OAuth auf
/// iOS/Android, sobald die App über `chronoapp://auth-callback` geöffnet wird.
Future<void> attachSupabaseAuthDeepLinks() async {
  if (!_isMobileAuthDeepLinkPlatform) return;

  final appLinks = AppLinks();

  Future<void> handleUri(Uri? uri) async {
    if (uri == null) return;
    if (!uriLooksLikeSupabaseAuthCallback(uri)) return;
    try {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
    } catch (_, _) {
      // Best-effort: Callback-Verarbeitung darf den App-Start nicht blockieren.
    }
  }

  appLinks.uriLinkStream.listen((uri) {
    unawaited(handleUri(uri));
  });
}
