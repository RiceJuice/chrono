import 'package:chronoapp/core/auth/auth_redirect_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'social_auth_service.dart';

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
  AuthRepository(this._client) : _socialAuth = SocialAuthService(_client);

  final SupabaseClient _client;
  final SocialAuthService _socialAuth;

  String? get currentUserEmail => _client.auth.currentUser?.email;

  /// `true`, wenn der Nutzer eine E-Mail/Passwort-Identität hat (nicht nur OAuth).
  bool get canChangePassword {
    final user = _client.auth.currentUser;
    if (user == null) return false;
    final identities = user.identities;
    if (identities != null && identities.isNotEmpty) {
      return identities.any((identity) => identity.provider == 'email');
    }
    final email = user.email?.trim();
    return email != null && email.isNotEmpty;
  }

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
    if (code == 'same_password' || msg.contains('same password')) {
      return 'Das neue Passwort muss sich vom aktuellen unterscheiden.';
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

  Future<AuthResponse> signInWithGoogle() async {
    final response = await _socialAuth.signInWithGoogle();
    await ensureProfileRowExists();
    return response;
  }

  Future<AuthResponse> signInWithApple() async {
    final response = await _socialAuth.signInWithApple();
    await ensureProfileRowExists();
    return response;
  }

  /// Legt eine fehlende [profiles]-Zeile an (Fallback, falls der DB-Trigger
  /// bei OAuth-Neuanmeldungen nicht greift).
  Future<void> ensureProfileRowExists() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final existing = await _client
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();
      if (existing != null) return;

      final meta = user.userMetadata ?? {};
      await _client.from('profiles').insert({
        'id': user.id,
        'first_name': _metaNamePart(meta, 'first_name', 'given_name'),
        'last_name': _metaNamePart(meta, 'last_name', 'family_name'),
      });
    } on AuthException catch (e) {
      throw AuthRepositoryException(_mapAuthException(e));
    } catch (_) {
      throw AuthRepositoryException(
        'Profil konnte nicht angelegt werden. Bitte erneut versuchen.',
      );
    }
  }

  static String _metaNamePart(
    Map<String, dynamic> meta,
    String primaryKey,
    String fallbackKey,
  ) {
    final primary = meta[primaryKey]?.toString().trim();
    if (primary != null && primary.isNotEmpty) return primary;
    final fallback = meta[fallbackKey]?.toString().trim();
    return fallback ?? '';
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
        emailRedirectTo: authEmailRedirectTo(),
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
        emailRedirectTo: authEmailRedirectTo(),
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

  /// Prüft, ob die E-Mail nach der Registrierung bestätigt wurde: zuerst
  /// Session-Refresh (falls bereits eine Session existiert), sonst Anmeldung.
  ///
  /// Gibt `false` zurück, solange [AuthException] wegen fehlender Bestätigung
  /// (`email_not_confirmed`) erwartbar ist; wirft bei anderen Auth-Fehlern.
  Future<bool> tryAdvanceAfterEmailConfirmation({
    required String email,
    required String password,
  }) async {
    final session = _client.auth.currentSession;
    if (session != null) {
      try {
        final response = await _client.auth.refreshSession();
        final user = response.user ?? _client.auth.currentUser;
        if (_isEmailConfirmed(user)) return true;
      } on AuthException {
        // Weiter mit Passwort-Anmeldung unten.
      }
    }

    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return true;
    } on AuthException catch (e) {
      final code = e.code?.toLowerCase();
      final msg = e.message.toLowerCase();
      if (code == 'email_not_confirmed' ||
          msg.contains('email not confirmed') ||
          msg.contains('email_not_confirmed')) {
        return false;
      }
      throw AuthRepositoryException(_mapAuthException(e));
    } catch (_) {
      throw AuthRepositoryException(
        'Anmeldung fehlgeschlagen. Bitte versuche es erneut.',
      );
    }
  }

  /// Ändert das Passwort nach Prüfung des aktuellen Passworts.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = currentUserEmail?.trim();
    if (email == null || email.isEmpty) {
      throw AuthRepositoryException('Nicht angemeldet.');
    }
    if (!canChangePassword) {
      throw AuthRepositoryException(
        'Passwort kann nur für E-Mail-Konten geändert werden.',
      );
    }

    try {
      await _client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw AuthRepositoryException(_mapAuthException(e));
    } on AuthRepositoryException {
      rethrow;
    } catch (_) {
      throw AuthRepositoryException(
        'Passwort konnte nicht geändert werden. Bitte erneut versuchen.',
      );
    }
  }

  /// Löscht das Konto unwiderruflich nach Passwort- bzw. E-Mail-Bestätigung.
  Future<void> deleteAccount({
    String? password,
    String? confirmationEmail,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw AuthRepositoryException('Nicht angemeldet.');
    }

    if (canChangePassword) {
      final trimmedPassword = password?.trim();
      if (trimmedPassword == null || trimmedPassword.isEmpty) {
        throw AuthRepositoryException('Bitte Passwort eingeben.');
      }
    } else {
      final email = currentUserEmail?.trim().toLowerCase();
      final confirmed = confirmationEmail?.trim().toLowerCase();
      if (email == null ||
          email.isEmpty ||
          confirmed == null ||
          confirmed != email) {
        throw AuthRepositoryException(
          'E-Mail-Adresse stimmt nicht mit deinem Konto überein.',
        );
      }
    }

    try {
      final response = await _client.functions.invoke(
        'delete-account',
        body: {
          if (canChangePassword) 'password': password!.trim(),
          if (!canChangePassword)
            'confirmationEmail': confirmationEmail!.trim(),
        },
      );

      if (response.status != 200) {
        final data = response.data;
        final message = data is Map && data['error'] != null
            ? data['error'].toString()
            : 'Konto konnte nicht gelöscht werden (${response.status}).';
        throw AuthRepositoryException(_mapDeleteAccountError(message));
      }

      try {
        await _client.auth.signOut();
      } catch (_) {
        // Nutzer ist serverseitig bereits gelöscht.
      }
    } on AuthRepositoryException {
      rethrow;
    } on AuthException catch (e) {
      throw AuthRepositoryException(_mapAuthException(e));
    } catch (_) {
      throw AuthRepositoryException(
        'Konto konnte nicht gelöscht werden. Bitte erneut versuchen.',
      );
    }
  }

  String _mapDeleteAccountError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('passwort') && lower.contains('ungültig')) {
      return 'Passwort ist ungültig.';
    }
    if (lower.contains('e-mail') && lower.contains('überein')) {
      return 'E-Mail-Adresse stimmt nicht mit deinem Konto überein.';
    }
    if (lower.contains('nicht angemeldet')) {
      return 'Nicht angemeldet.';
    }
    return message.trim().isNotEmpty
        ? message
        : 'Konto konnte nicht gelöscht werden. Bitte erneut versuchen.';
  }

  /// Aktualisiert nur übergebene Felder in [public.profiles] für den aktuellen User.
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? className,
    String? schoolTrack,
    String? voice,
    String? diet,
    String? role,
    String? choir,
    String? activeChildId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw AuthRepositoryException('Nicht angemeldet.');
    }

    final updates = <String, dynamic>{};
    if (firstName != null) updates['first_name'] = firstName.trim();
    if (lastName != null) updates['last_name'] = lastName.trim();
    if (className != null) updates['class_name'] = className;
    if (schoolTrack != null) updates['schooltrack'] = schoolTrack;
    if (voice != null) updates['voice'] = voice;
    if (diet != null) updates['diet'] = diet;
    if (role != null) updates['role'] = role;
    if (choir != null) updates['choir'] = choir;
    if (activeChildId != null) updates['active_child_id'] = activeChildId;

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

  /// Schließt das Onboarding serverseitig ab (setzt u. a. onboarding_completed_at).
  Future<bool> completeOnboarding({String? activeChildId}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw AuthRepositoryException('Nicht angemeldet.');
    }

    try {
      final result = await _client.rpc(
        'complete_user_onboarding',
        params: {
          if (activeChildId != null && activeChildId.isNotEmpty)
            'p_active_child_id': activeChildId,
        },
      );
      if (result == true) return true;
      throw AuthRepositoryException(
        'Onboarding konnte nicht abgeschlossen werden. Bitte alle Schritte prüfen.',
      );
    } on AuthRepositoryException {
      rethrow;
    } on PostgrestException catch (e) {
      throw AuthRepositoryException(
        e.message.trim().isNotEmpty
            ? e.message
            : 'Onboarding konnte nicht abgeschlossen werden.',
      );
    } catch (_) {
      throw AuthRepositoryException(
        'Onboarding konnte nicht abgeschlossen werden. Bitte erneut versuchen.',
      );
    }
  }
}
