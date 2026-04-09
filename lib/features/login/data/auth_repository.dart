import 'package:supabase_flutter/supabase_flutter.dart';

/// Nutzerorientierte Fehlermeldung aus der Auth-/Profil-Schicht.
class AuthRepositoryException implements Exception {
  AuthRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

enum SignUpOutcome {
  registeredAndSignedIn,
  registeredNeedsEmailVerification,
}

class SignUpResult {
  const SignUpResult({
    required this.outcome,
    required this.email,
  });

  final SignUpOutcome outcome;
  final String email;
}

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  String? get currentUserEmail => _client.auth.currentUser?.email;

  String _mapAuthException(AuthException e) {
    final msg = e.message.toLowerCase();
    final status = e.statusCode;
    final code = e.code?.toLowerCase();

    if (code == 'invalid_credentials' ||
        msg.contains('invalid login') ||
        msg.contains('invalid credentials')) {
      return 'E-Mail oder Passwort ist ungültig.';
    }
    if (code == 'email_not_confirmed' ||
        msg.contains('email not confirmed') ||
        msg.contains('email_not_confirmed')) {
      return 'Bitte bestätige zuerst deine E-Mail-Adresse.';
    }
    if (code == 'user_already_exists' ||
        msg.contains('user already registered') ||
        msg.contains('already been registered')) {
      return 'Diese E-Mail ist bereits registriert.';
    }
    if (msg.contains('password') &&
        (msg.contains('weak') || msg.contains('short'))) {
      return 'Das Passwort ist zu schwach oder zu kurz.';
    }
    if (msg.contains('rate limit') || status == '429') {
      return 'Zu viele Versuche. Bitte warte kurz und versuche es erneut.';
    }
    if (status == '400' && msg.contains('email')) {
      return 'Bitte gib eine gültige E-Mail-Adresse ein.';
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

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (e) {
      throw AuthRepositoryException(_mapAuthException(e));
    } catch (_) {
      throw AuthRepositoryException(
        'Anmeldung fehlgeschlagen. Bitte versuche es erneut.',
      );
    }
  }

  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    try {
      await _ensureCleanSignUpState();
      final response = await _client.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: {
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
        },
      );
      final isSignedIn = response.session != null;
      return SignUpResult(
        outcome: isSignedIn
            ? SignUpOutcome.registeredAndSignedIn
            : SignUpOutcome.registeredNeedsEmailVerification,
        email: normalizedEmail,
      );
    } on AuthException catch (e) {
      throw AuthRepositoryException(_mapAuthException(e));
    } catch (_) {
      throw AuthRepositoryException(
        'Registrierung fehlgeschlagen. Bitte versuche es erneut.',
      );
    }
  }

  Future<void> _ensureCleanSignUpState() async {
    final session = _client.auth.currentSession;
    if (session == null) return;
    try {
      await _client.auth.refreshSession();
    } on AuthException {
      try {
        await _client.auth.signOut();
      } catch (_) {
        // Best effort cleanup: signup should continue unauthenticated.
      }
    }
  }

  Future<void> resendConfirmationEmail({required String email}) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      if (normalizedEmail.isEmpty) {
        throw AuthRepositoryException(
          'Keine E-Mail-Adresse vorhanden. Bitte erneut registrieren.',
        );
      }
      await _client.auth.resend(
        type: OtpType.signup,
        email: normalizedEmail,
      );
    } on AuthException catch (e) {
      throw AuthRepositoryException(_mapAuthException(e));
    } on AuthRepositoryException {
      rethrow;
    } catch (_) {
      throw AuthRepositoryException(
        'Bestätigungs-E-Mail konnte nicht erneut gesendet werden.',
      );
    }
  }

  Future<bool> refreshUserVerificationState() async {
    try {
      final currentSession = _client.auth.currentSession;
      if (currentSession == null) return false;
      final response = await _client.auth.refreshSession();
      final user = response.user ?? _client.auth.currentUser;
      return _isEmailConfirmed(user);
    } on AuthException catch (e) {
      throw AuthRepositoryException(_mapAuthException(e));
    } catch (_) {
      throw AuthRepositoryException(
        'Bestätigungsstatus konnte nicht geprüft werden.',
      );
    }
  }

  bool _isEmailConfirmed(User? user) {
    if (user == null) return false;
    if (user.emailConfirmedAt != null) return true;
    final raw = user.toJson()['email_confirmed_at'];
    return raw != null && raw.toString().trim().isNotEmpty;
  }

  /// Aktualisiert nur übergebene Felder in [public.profiles] für den aktuellen User.
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? className,
    String? voice,
    String? diet,
    String? role,
    String? choir,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw AuthRepositoryException('Nicht angemeldet.');
    }

    final updates = <String, dynamic>{};
    if (firstName != null) updates['first_name'] = firstName.trim();
    if (lastName != null) updates['last_name'] = lastName.trim();
    if (className != null) updates['class_name'] = className;
    if (voice != null) updates['voice'] = voice;
    if (diet != null) updates['diet'] = diet;
    if (role != null) updates['role'] = role;
    if (choir != null) updates['choir'] = choir;

    if (updates.isEmpty) return true;

    try {
      final updatedRows = await _client
          .from('profiles')
          .update(updates)
          .eq('id', user.id)
          .select('id');
      if (updatedRows.isNotEmpty) return true;
      throw AuthRepositoryException(
        'Profil konnte nicht gespeichert werden. Bitte erneut versuchen.',
      );
    } on AuthException catch (e) {
      throw AuthRepositoryException(_mapAuthException(e));
    } on AuthRepositoryException {
      rethrow;
    } catch (e) {
      throw AuthRepositoryException(
        'Profil konnte nicht gespeichert werden. Bitte erneut versuchen.',
      );
    }
  }
}
