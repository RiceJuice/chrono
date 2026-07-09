import 'dart:io' show Platform;

import 'package:chronoapp/features/calendar/domain/filter/event_schedule_filter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/push/push_device_repository.dart';

/// Persistiert Ablaufplan-Filter und synct Live-Activity-Tokens nach Supabase.
class ScheduleLiveActivityRepository {
  ScheduleLiveActivityRepository({
    SupabaseClient? client,
    SharedPreferences? prefs,
    PushDeviceRepository? pushDeviceRepository,
  })  : _client = client ?? Supabase.instance.client,
        _prefs = prefs,
        _pushDeviceRepository = pushDeviceRepository ?? PushDeviceRepository();

  static const String scheduleFilterPrefsKey = 'schedule_list_filter';

  final SupabaseClient _client;
  final SharedPreferences? _prefs;
  final PushDeviceRepository _pushDeviceRepository;

  Future<EventScheduleListFilter> loadScheduleFilter() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final raw = prefs.getString(scheduleFilterPrefsKey);
    if (raw == 'mine') return EventScheduleListFilter.mine;
    return EventScheduleListFilter.all;
  }

  Future<void> saveScheduleFilter(EventScheduleListFilter filter) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final value = filter == EventScheduleListFilter.mine ? 'mine' : 'all';
    await prefs.setString(scheduleFilterPrefsKey, value);
    await _syncDeviceMetadata(scheduleFilter: value);
  }

  Future<String> _deviceInstallId() =>
      _pushDeviceRepository.deviceInstallId();

  Future<void> syncLiveActivityPushToken(String token) async {
    await _syncDeviceMetadata(liveActivityPushToken: token);
  }

  Future<void> syncPushToStartToken(String token) async {
    await _syncDeviceMetadata(pushToStartToken: token);
  }

  Future<void> clearLiveActivityTokens() async {
    await _syncDeviceMetadata(
      liveActivityPushToken: '',
      pushToStartToken: '',
      clearTokens: true,
    );
  }

  String? _platformLabel() {
    if (kIsWeb) return null;
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return null;
  }

  Future<void> _syncDeviceMetadata({
    String? scheduleFilter,
    String? liveActivityPushToken,
    String? pushToStartToken,
    bool clearTokens = false,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final deviceId = await _deviceInstallId();
      final patch = <String, dynamic>{
        'user_id': userId,
        'device_id': deviceId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (scheduleFilter != null) {
        patch['schedule_filter'] = scheduleFilter;
      }
      if (clearTokens) {
        patch['live_activity_push_token'] = null;
        patch['push_to_start_token'] = null;
      } else {
        if (liveActivityPushToken != null && liveActivityPushToken.isNotEmpty) {
          patch['live_activity_push_token'] = liveActivityPushToken;
        }
        if (pushToStartToken != null && pushToStartToken.isNotEmpty) {
          patch['push_to_start_token'] = pushToStartToken;
        }
      }

      // Upsert statt Update: Die Live-Activity-Token-Streams (Push-to-Start/
      // Activity-Token) koennen beim App-Start VOR der FCM-Token-Registrierung
      // feuern (Bootstrap-Reihenfolge ist nicht garantiert). Ein reines
      // update() auf eine noch nicht existierende Zeile ist ein stiller
      // No-op -> der Token geht dauerhaft verloren, bis die Streams erneut
      // feuern (was oft nie wieder passiert). Deshalb hier per upsert
      // sicherstellen, dass die Zeile inkl. der NOT-NULL-Spalten
      // (fcm_token, platform) existiert.
      final existing = await _client
          .from('profile_push_devices')
          .select('fcm_token')
          .eq('user_id', userId)
          .eq('device_id', deviceId)
          .maybeSingle();

      if (existing == null) {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        final platform = _platformLabel();
        if (fcmToken == null || fcmToken.isEmpty || platform == null) {
          // Ohne fcm_token/platform kann die NOT-NULL-Zeile nicht angelegt
          // werden - in diesem Fall bleibt es beim No-op wie zuvor.
          return;
        }
        patch['fcm_token'] = fcmToken;
        patch['platform'] = platform;
      }

      await _client
          .from('profile_push_devices')
          .upsert(patch, onConflict: 'user_id,device_id');
    } catch (_) {
      // Sync darf App nicht blockieren.
    }
  }
}
