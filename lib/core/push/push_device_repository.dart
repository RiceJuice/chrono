import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// FCM-Token pro Gerät in [public.profile_push_devices] (mehrere Geräte pro User).
class PushDeviceRepository {
  PushDeviceRepository({
    SupabaseClient? client,
    SharedPreferences? prefs,
  })  : _client = client ?? Supabase.instance.client,
        _prefs = prefs;

  static const String _deviceIdPrefsKey = 'push_device_install_id';

  final SupabaseClient _client;
  final SharedPreferences? _prefs;

  Future<String> _deviceInstallId() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdPrefsKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = _newInstallId();
    await prefs.setString(_deviceIdPrefsKey, id);
    return id;
  }

  static String _newInstallId() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    return '${hex(bytes[0])}${hex(bytes[1])}${hex(bytes[2])}${hex(bytes[3])}-'
        '${hex(bytes[4])}${hex(bytes[5])}-'
        '${hex(bytes[6])}${hex(bytes[7])}-'
        '${hex(bytes[8])}${hex(bytes[9])}-'
        '${hex(bytes[10])}${hex(bytes[11])}${hex(bytes[12])}${hex(bytes[13])}${hex(bytes[14])}${hex(bytes[15])}';
  }

  String? _platformLabel() {
    if (kIsWeb) return null;
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return null;
  }

  Future<void> saveToken(String token) async {
    final userId = _client.auth.currentUser?.id;
    final platform = _platformLabel();
    if (userId == null || platform == null) return;

    final deviceId = await _deviceInstallId();
    final now = DateTime.now().toUtc().toIso8601String();

    await _client.from('profile_push_devices').upsert(
      {
        'user_id': userId,
        'device_id': deviceId,
        'fcm_token': token,
        'platform': platform,
        'updated_at': now,
      },
      onConflict: 'user_id,device_id',
    );

    // profiles.fcm_token nicht mehr befüllen (Legacy, nur profile_push_devices).
  }

  Future<void> clearTokenForCurrentDevice() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final deviceId = await _deviceInstallId();
      await _client
          .from('profile_push_devices')
          .delete()
          .eq('user_id', userId)
          .eq('device_id', deviceId);
    } catch (_) {
      // Abmeldung soll nicht scheitern.
    }
  }
}
