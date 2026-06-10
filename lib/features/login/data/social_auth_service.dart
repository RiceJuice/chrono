import 'dart:async';
import 'dart:convert';

import 'package:chronoapp/core/auth/auth_redirect_config.dart';
import 'package:chronoapp/core/auth/social_auth_config.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_repository.dart';

/// Native/OAuth Social-Login für Google und Apple.
class SocialAuthService {
  SocialAuthService(this._client);

  final SupabaseClient _client;

  static const _googleScopes = <String>['email', 'profile'];
  static const _oauthWaitTimeout = Duration(minutes: 3);

  static bool _googleInitialized = false;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    if (!isGoogleSignInConfigured) {
      throw AuthRepositoryException(
        'Google-Anmeldung ist noch nicht konfiguriert.',
      );
    }
    await GoogleSignIn.instance.initialize(
      serverClientId: kGoogleWebClientId,
      clientId: defaultTargetPlatform == TargetPlatform.iOS
          ? kGoogleIosClientId
          : null,
    );
    _googleInitialized = true;
  }

  Future<AuthResponse> signInWithGoogle() async {
    await _ensureGoogleInitialized();
    try {
      final googleUser = await GoogleSignIn.instance.authenticate(
        scopeHint: _googleScopes,
      );
      final idToken = googleUser.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw AuthRepositoryException(
          'Google-Anmeldung fehlgeschlagen. Kein ID-Token erhalten.',
        );
      }

      final authorization = await googleUser.authorizationClient
              .authorizationForScopes(_googleScopes) ??
          await googleUser.authorizationClient.authorizeScopes(_googleScopes);

      return await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: authorization.accessToken,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        throw const AuthSignInCancelledException();
      }
      throw AuthRepositoryException(
        'Google-Anmeldung fehlgeschlagen. Bitte versuche es erneut.',
      );
    } on AuthException catch (e) {
      throw AuthRepositoryException(_mapAuthException(e));
    }
  }

  Future<AuthResponse> signInWithApple() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _signInWithAppleNative();
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _signInWithAppleOAuth();
    }
    throw AuthRepositoryException(
      'Apple-Anmeldung wird auf dieser Plattform nicht unterstützt.',
    );
  }

  Future<AuthResponse> _signInWithAppleNative() async {
    final rawNonce = _client.auth.generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw AuthRepositoryException(
          'Apple-Anmeldung fehlgeschlagen. Kein ID-Token erhalten.',
        );
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      if (credential.givenName != null || credential.familyName != null) {
        final nameParts = <String>[
          if (credential.givenName != null) credential.givenName!,
          if (credential.familyName != null) credential.familyName!,
        ];
        await _client.auth.updateUser(
          UserAttributes(
            data: {
              'full_name': nameParts.join(' '),
              'given_name': credential.givenName,
              'family_name': credential.familyName,
            },
          ),
        );
      }

      return response;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AuthSignInCancelledException();
      }
      throw AuthRepositoryException(
        'Apple-Anmeldung fehlgeschlagen. Bitte versuche es erneut.',
      );
    } on AuthException catch (e) {
      throw AuthRepositoryException(_mapAuthException(e));
    }
  }

  Future<AuthResponse> _signInWithAppleOAuth() async {
    final redirectTo = authOAuthRedirectTo();
    final completer = Completer<void>();
    late final StreamSubscription<AuthState> subscription;

    subscription = _client.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.signedIn &&
          state.session != null &&
          !completer.isCompleted) {
        completer.complete();
      }
    });

    try {
      final launched = await _client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: redirectTo,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw AuthRepositoryException(
          'Apple-Anmeldung konnte nicht gestartet werden.',
        );
      }

      await completer.future.timeout(_oauthWaitTimeout);
      final session = _client.auth.currentSession;
      if (session == null) {
        throw AuthRepositoryException(
          'Apple-Anmeldung fehlgeschlagen. Bitte versuche es erneut.',
        );
      }
      return AuthResponse(session: session);
    } on TimeoutException {
      throw const AuthSignInCancelledException();
    } on AuthException catch (e) {
      throw AuthRepositoryException(_mapAuthException(e));
    } finally {
      await subscription.cancel();
    }
  }

  String _mapAuthException(AuthException e) {
    final msg = e.message.toLowerCase();
    final code = e.code?.toLowerCase();

    if (code == 'provider_disabled' || msg.contains('provider is disabled')) {
      return 'Dieser Anmeldeanbieter ist derzeit nicht verfügbar.';
    }
    if (code == 'invalid_grant' || msg.contains('invalid grant')) {
      return 'Anmeldung abgelaufen. Bitte versuche es erneut.';
    }
    if (msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('failed host lookup')) {
      return 'Netzwerkfehler. Bitte Verbindung prüfen und erneut versuchen.';
    }
    if (e.message.trim().isNotEmpty) {
      return e.message;
    }
    return 'Anmeldung fehlgeschlagen. Bitte versuche es erneut.';
  }
}

/// Wird geworfen, wenn der Nutzer den Social-Login-Dialog abbricht.
class AuthSignInCancelledException implements Exception {
  const AuthSignInCancelledException();
}
