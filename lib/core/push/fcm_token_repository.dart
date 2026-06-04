import 'package:supabase_flutter/supabase_flutter.dart';

/// Speichert/löscht den FCM-Token in [public.profiles] (eigene Zeile, RLS).
class FcmTokenRepository {
  FcmTokenRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> saveToken(String token) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('profiles').update({
      'fcm_token': token,
      'fcm_token_updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', userId);
  }

  Future<void> clearToken() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _client.from('profiles').update({
        'fcm_token': null,
        'fcm_token_updated_at': null,
      }).eq('id', userId);
    } catch (_) {
      // Abmeldung soll nicht scheitern, wenn das Profil nicht erreichbar ist.
    }
  }
}
