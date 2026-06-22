import 'package:chronoapp/core/auth/auth_redirect_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uriLooksLikeSupabaseAuthCallback erkennt chronoapp-Schema', () {
    expect(
      uriLooksLikeSupabaseAuthCallback(Uri.parse('chronoapp://auth-callback')),
      isTrue,
    );
  });

  test('uriLooksLikeSupabaseAuthCallback erkennt Token im Fragment', () {
    expect(
      uriLooksLikeSupabaseAuthCallback(
        Uri.parse('https://example.com/callback#access_token=abc'),
      ),
      isTrue,
    );
  });

  test('uriLooksLikeSupabaseAuthCallback ignoriert Ablaufplan-Deep-Link', () {
    expect(
      uriLooksLikeSupabaseAuthCallback(
        Uri.parse('chronoapp://schedule?eventId=abc'),
      ),
      isFalse,
    );
  });

  test('uriLooksLikeSupabaseAuthCallback ignoriert fremde URLs', () {
    expect(
      uriLooksLikeSupabaseAuthCallback(Uri.parse('https://domspatzen.de/')),
      isFalse,
    );
  });
}
