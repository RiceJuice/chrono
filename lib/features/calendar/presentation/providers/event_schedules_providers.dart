import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../data/event_schedules_repository.dart';
import '../../domain/models/event_schedule.dart';

final eventSchedulesRepositoryProvider = Provider<EventSchedulesRepository>((
  ref,
) {
  return EventSchedulesRepository(ref.watch(dbProvider));
});

/// Ablaufplanpunkte für einen Termin (alle, ohne Filter).
///
/// Später: [eventScheduleVisible] aus Domain vor dem Yield anwenden.
final eventSchedulesForEntryProvider =
    StreamProvider.family<List<EventSchedule>, String>((ref, eventId) {
      return ref.watch(eventSchedulesRepositoryProvider).watchForEvent(eventId);
    });
