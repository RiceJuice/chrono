import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/filter/event_schedule_filter.dart';
import '../data/schedule_live_activity_repository.dart';

final scheduleLiveActivityRepositoryProvider =
    Provider<ScheduleLiveActivityRepository>((ref) {
  return ScheduleLiveActivityRepository();
});

final scheduleListFilterProvider =
    AsyncNotifierProvider<ScheduleListFilterNotifier, EventScheduleListFilter>(
  ScheduleListFilterNotifier.new,
);

class ScheduleListFilterNotifier extends AsyncNotifier<EventScheduleListFilter> {
  @override
  Future<EventScheduleListFilter> build() async {
    return ref.read(scheduleLiveActivityRepositoryProvider).loadScheduleFilter();
  }

  Future<void> setFilter(EventScheduleListFilter filter) async {
    state = AsyncData(filter);
    await ref.read(scheduleLiveActivityRepositoryProvider).saveScheduleFilter(
          filter,
        );
  }
}
