import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:live_activities/live_activities.dart';
import 'package:live_activities/models/activity_update.dart';

import 'package:live_activities/models/url_scheme_data.dart';

import '../domain/schedule_live_activity_snapshot.dart';
import '../live_activity_constants.dart';

/// Wrapper um das live_activities-Plugin.
class ScheduleLiveActivityService {
  ScheduleLiveActivityService({LiveActivities? plugin})
      : _plugin = plugin ?? LiveActivities();

  final LiveActivities _plugin;
  bool _initialized = false;

  StreamSubscription<ActivityUpdate>? _activitySub;
  StreamSubscription<String>? _pushToStartSub;
  StreamSubscription<UrlSchemeData>? _urlSchemeSub;

  void Function(String token)? onLiveActivityPushToken;
  void Function(String token)? onPushToStartToken;
  void Function(UrlSchemeData data)? onUrlScheme;

  static bool get supportsLiveActivities =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  Future<bool> init() async {
    if (!supportsLiveActivities) return false;
    if (_initialized) return true;

    await _plugin.init(
      appGroupId: kLiveActivityAppGroupId,
      urlScheme: kLiveActivityUrlScheme,
    );

    _activitySub = _plugin.activityUpdateStream.listen((update) {
      update.map(
        active: (activity) {
          final token = activity.activityToken;
          if (token.isNotEmpty) {
            onLiveActivityPushToken?.call(token);
          }
        },
        ended: (_) {},
        stale: (_) {},
        unknown: (_) {},
      );
    });

    _pushToStartSub = _plugin.pushToStartTokenUpdateStream.listen((token) {
      if (token.isNotEmpty) {
        onPushToStartToken?.call(token);
      }
    });

    _urlSchemeSub = _plugin.urlSchemeStream().listen((data) {
      onUrlScheme?.call(data);
    });

    _initialized = true;
    return true;
  }

  Future<bool> areActivitiesEnabled() async {
    if (!supportsLiveActivities || !_initialized) return false;
    try {
      return await _plugin.areActivitiesEnabled();
    } catch (_) {
      return false;
    }
  }

  Future<String?> createOrUpdate(ScheduleLiveActivitySnapshot snapshot) async {
    if (!supportsLiveActivities || !_initialized) return null;
    try {
      return await _plugin.createOrUpdateActivity(
        snapshot.customId,
        snapshot.toActivityPayload(),
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[LiveActivity] createOrUpdate failed: $e\n$st');
      }
      return null;
    }
  }

  Future<void> end(String customId) async {
    if (!supportsLiveActivities || !_initialized) return;
    try {
      await _plugin.endActivity(customId);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[LiveActivity] end failed: $e\n$st');
      }
    }
  }

  Future<void> endAll() async {
    if (!supportsLiveActivities || !_initialized) return;
    try {
      await _plugin.endAllActivities();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _activitySub?.cancel();
    await _pushToStartSub?.cancel();
    await _urlSchemeSub?.cancel();
    _activitySub = null;
    _pushToStartSub = null;
    _urlSchemeSub = null;
    if (_initialized) {
      await _plugin.dispose();
      _initialized = false;
    }
  }
}
