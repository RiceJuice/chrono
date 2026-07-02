import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:live_activities/models/url_scheme_data.dart';

import '../../presentation/providers/calendar_providers.dart';
import '../live_activity_constants.dart';
import '../../timetable_live_activity/timetable_live_activity_constants.dart';
import 'schedule_live_activity_deep_link_pending.dart';
import 'schedule_live_activity_open_request_provider.dart';

/// Verarbeitet Deep Links aus der Live Activity und öffnet den Ablaufplan.
class ScheduleLiveActivityDeepLinkHandler {
  ScheduleLiveActivityDeepLinkHandler({
    required GoRouter router,
    required WidgetRef ref,
  })  : _router = router,
        _ref = ref;

  final GoRouter _router;
  final WidgetRef _ref;
  final AppLinks _appLinks = AppLinks();

  StreamSubscription<Uri>? _appLinkSub;

  Future<void> start() async {
    await _handleUri(await _appLinks.getInitialLink());
    _appLinkSub = _appLinks.uriLinkStream.listen((uri) {
      unawaited(_handleUri(uri));
    });
  }

  void handleUrlSchemeData(UrlSchemeData data) {
    final uri = data.url == null ? null : Uri.tryParse(data.url!);
    if (uri != null) {
      unawaited(_handleUri(uri));
      return;
    }

    if (data.scheme != kLiveActivityUrlScheme) {
      return;
    }

    if (data.host == kTimetableLiveActivityDeepLinkHost) {
      for (final item in data.queryParameters) {
        if (item['name'] == 'date') {
          final dayDateKey = item['value']?.trim();
          if (dayDateKey != null && dayDateKey.isNotEmpty) {
            _openTimetable(dayDateKey);
          }
          return;
        }
      }
      return;
    }

    if (data.host != kLiveActivityScheduleDeepLinkHost) {
      return;
    }

    for (final item in data.queryParameters) {
      if (item['name'] == 'eventId') {
        final eventId = item['value']?.trim();
        if (eventId != null && eventId.isNotEmpty) {
          _openSchedule(eventId);
        }
        return;
      }
    }
  }

  Future<void> _handleUri(Uri? uri) async {
    if (uri == null) return;

    final timetableDay = parseTimetableLiveActivityDayDateKey(uri);
    if (timetableDay != null) {
      _openTimetable(timetableDay);
      return;
    }

    final eventId = parseScheduleLiveActivityEventId(uri);
    if (eventId == null) return;
    _openSchedule(eventId);
  }

  void _openTimetable(String dayDateKey) {
    final parts = dayDateKey.split('-');
    if (parts.length == 3) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      if (year != null && month != null && day != null) {
        _ref.read(selectedDayProvider.notifier).update(
              DateTime(year, month, day),
            );
        _ref.read(focusedDayProvider.notifier).update(DateTime(year, month, day));
      }
    }
    _router.go('/calendar');
    if (kDebugMode) {
      debugPrint('[LiveActivity] open timetable deep link for $dayDateKey');
    }
  }

  void _openSchedule(String eventId) {
    ScheduleLiveActivityDeepLinkPending.set(eventId);
    _router.go('/calendar');
    Future<void>.delayed(Duration.zero, () {
      _ref.read(scheduleLiveActivityOpenRequestProvider.notifier).open(eventId);
    });
    if (kDebugMode) {
      debugPrint('[LiveActivity] open schedule deep link for $eventId');
    }
  }

  Future<void> dispose() async {
    await _appLinkSub?.cancel();
    _appLinkSub = null;
  }
}
