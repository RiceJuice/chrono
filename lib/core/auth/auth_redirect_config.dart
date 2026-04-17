import 'package:flutter/foundation.dart';

/// Redirect nach E-Mail-Bestätigung (Supabase `emailRedirectTo`).
///
/// **Supabase Dashboard:** Authentication → URL configuration → Redirect URLs:
/// `chronoapp://auth-callback` eintragen (für iOS/macOS-Builds).
const String kAppleAuthEmailRedirectUrl = 'chronoapp://auth-callback';

const String kAuthEmailRedirectFallbackUrl = 'https://domspatzen.de/';

/// iOS/macOS: Custom-URL, damit die App aus der Mail geöffnet wird.
/// Sonst: öffentliche Fallback-Seite.
String authEmailRedirectTo() {
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return kAppleAuthEmailRedirectUrl;
    default:
      return kAuthEmailRedirectFallbackUrl;
  }
}

/// True, wenn die URI wahrscheinlich ein Supabase-Auth-Callback ist
/// (Apple-Schema oder Token/Code in Query/Fragment).
bool uriLooksLikeSupabaseAuthCallback(Uri uri) {
  if (uri.scheme == 'chronoapp') return true;
  final combined = '${uri.query}&${uri.fragment}';
  return combined.contains('access_token=') ||
      combined.contains('refresh_token=') ||
      combined.contains('code=');
}
