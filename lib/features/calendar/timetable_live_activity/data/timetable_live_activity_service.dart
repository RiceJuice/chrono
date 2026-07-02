import 'package:chronoapp/features/calendar/live_activity/data/schedule_live_activity_service.dart';
import 'package:chronoapp/features/calendar/timetable_live_activity/domain/timetable_live_activity_snapshot.dart';

/// Wrapper für Stundenplan-Live-Activities (teilt Plugin-Init mit Ablaufplan).
class TimetableLiveActivityService {
  TimetableLiveActivityService({ScheduleLiveActivityService? sharedService})
      : _sharedService = sharedService ?? ScheduleLiveActivityService();

  final ScheduleLiveActivityService _sharedService;

  Future<bool> init() => _sharedService.init();

  Future<bool> areActivitiesEnabled() => _sharedService.areActivitiesEnabled();

  Future<String?> createOrUpdate(TimetableLiveActivitySnapshot snapshot) {
    return _sharedService.createOrUpdatePayload(
      snapshot.customId,
      snapshot.toActivityPayload(),
    );
  }

  Future<void> end(String customId) => _sharedService.end(customId);

  set onLiveActivityPushToken(void Function(String token)? handler) {
    _sharedService.onLiveActivityPushToken = handler;
  }

  set onPushToStartToken(void Function(String token)? handler) {
    _sharedService.onPushToStartToken = handler;
  }

  set onUrlScheme(void Function(dynamic data)? handler) {
    _sharedService.onUrlScheme = handler;
  }
}
