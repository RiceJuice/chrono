import 'package:supabase_flutter/supabase_flutter.dart';

/// Nutzerorientierte Fehlermeldung aus der Auth-/Profil-Schicht.
class AuthRepositoryException implements Exception {
  AuthRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  String _mapAuthException(AuthException e) {
    final msg = e.message.toLowerCase();
    final status = e.statusCode;

    if (msg.contains('invalid login') ||
        msg.contains('invalid credentials') ||
        status == '400' && msg.contains('email')) {
      return 'E-Mail oder Passwort ist ungültig.';
    }
    if (msg.contains('email not confirmed') ||
        msg.contains('email_not_confirmed')) {
      return 'Bitte bestätige zuerst deine E-Mail-Adresse.';
    }
    if (msg.contains('user already registered') ||
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
    if (msg.contains('network') || msg.contains('socket')) {
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
    }
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      return await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
        },
      );
    } on AuthException catch (e) {
      throw AuthRepositoryException(_mapAuthException(e));
    }
  }

  /// Aktualisiert nur übergebene Felder in [public.profiles] für den aktuellen User.
  Future<void> updateProfile({
    String? klasseId,
    String? chorId,
    String? stimmgruppe,
    String? ernaehrung,
    String? role,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw AuthRepositoryException('Nicht angemeldet.');
    }

    final updates = <String, dynamic>{};
    if (klasseId != null) updates['klasse_id'] = klasseId;
    if (chorId != null) updates['chor_id'] = chorId;
    if (stimmgruppe != null) updates['stimmgruppe'] = stimmgruppe;
    if (ernaehrung != null) updates['ernaehrung'] = ernaehrung;
    if (role != null) updates['role'] = role;

    if (updates.isEmpty) return;

    try {
      await _client.from('profiles').update(updates).eq('id', user.id);
    } on AuthException catch (e) {
      throw AuthRepositoryException(_mapAuthException(e));
    } catch (e) {
      throw AuthRepositoryException(
        'Profil konnte nicht gespeichert werden. Bitte erneut versuchen.',
      );
    }
  }
}
