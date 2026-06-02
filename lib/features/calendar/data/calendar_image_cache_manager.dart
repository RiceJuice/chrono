import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Disk-Cache für Kalender-Event-Bilder (längere Haltedauer als der Default).
abstract final class CalendarImageCacheManager {
  static const _cacheKey = 'chronoCalendarEventImages';

  static final CacheManager instance = CacheManager(
    Config(
      _cacheKey,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 300,
    ),
  );
}
