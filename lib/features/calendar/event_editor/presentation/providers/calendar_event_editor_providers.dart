import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/database/database_provider.dart';
import '../../data/calendar_event_series_reader.dart';
import '../../data/calendar_event_target_resolver.dart';
import '../../data/calendar_event_write_repository.dart';

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
