import 'package:chronoapp/features/calendar/domain/filter/event_schedule_filter.dart';
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

      await _client
          .from('profile_push_devices')
          .update(patch)
          .eq('user_id', userId)
          .eq('device_id', deviceId);
    } catch (_) {
      // Sync darf App nicht blockieren.
    }
  }
}
