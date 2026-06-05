import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/database/database_provider.dart';
import '../../data/calendar_event_image_upload_service.dart';
import '../../data/calendar_event_source_upload_service.dart';
import '../../data/calendar_event_series_reader.dart';
import '../../data/calendar_event_target_resolver.dart';
import '../../data/calendar_event_write_repository.dart';
import '../../data/event_broadcast_service.dart';

final calendarEventWriteRepositoryProvider =
    Provider<CalendarEventWriteRepository>((ref) {
      return CalendarEventWriteRepository(ref.watch(dbProvider));
    });

final calendarEventTargetResolverProvider =
    Provider<CalendarEventTargetResolver>((ref) {
      return CalendarEventTargetResolver(ref.watch(dbProvider));
    });

final calendarEventSeriesReaderProvider =
    Provider<CalendarEventSeriesReader>((ref) {
      return CalendarEventSeriesReader(ref.watch(dbProvider));
    });

final calendarEventImageUploadServiceProvider =
    Provider<CalendarEventImageUploadService>((ref) {
      return CalendarEventImageUploadService();
    });

final calendarEventSourceUploadServiceProvider =
    Provider<CalendarEventSourceUploadService>((ref) {
      return CalendarEventSourceUploadService();
    });

final eventBroadcastServiceProvider = Provider<EventBroadcastService>((ref) {
  return EventBroadcastService();
});
