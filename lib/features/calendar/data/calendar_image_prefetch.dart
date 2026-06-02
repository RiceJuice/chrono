import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/models/calendar_entry.dart';
import 'calendar_image_cache_key.dart';
import 'calendar_image_cache_manager.dart';
import 'calendar_image_file_cache.dart';
import 'calendar_images.dart';
import 'calendar_signed_url_cache.dart';

/// Lädt Event-Bilder im Hintergrund vor, damit Karten sie sofort aus dem Cache zeigen.
abstract final class CalendarImagePrefetch {
  static final Set<String> _scheduledKeys = <String>{};

  static void prefetchEntries(Iterable<CalendarEntry> entries) {
    if (kIsWeb) return;
    unawaited(_prefetchEntries(entries));
  }

  static Future<void> _prefetchEntries(Iterable<CalendarEntry> entries) async {
    await CalendarSignedUrlCache.shared.ensureLoaded();

    for (final entry in entries) {
      final paths = entry.imagePaths;
      final urls = entry.imageUrls;
      if ((paths == null || paths.isEmpty) && (urls == null || urls.isEmpty)) {
        continue;
      }

      final cacheKey = calendarEventImageCacheKey(
        entryId: entry.id,
        imageIndex: 0,
        entry: entry,
      );
      if (_scheduledKeys.contains(cacheKey)) continue;
      _scheduledKeys.add(cacheKey);

      if (CalendarImageFileCache.peek(cacheKey) != null) continue;

      final existingFile = await CalendarImageFileCache.resolve(cacheKey);
      if (existingFile != null) continue;

      String? url;
      if (urls != null && urls.isNotEmpty) {
        url = urls.first;
      } else if (paths != null && paths.isNotEmpty) {
        final resolved = await CalendarImages.urlResolver.resolveSignedUrls(
          paths,
        );
        if (resolved != null && resolved.isNotEmpty) {
          url = resolved.first;
        }
      }
      if (url == null || url.isEmpty) continue;

      try {
        final file = await CalendarImageCacheManager.instance.downloadFile(
          url,
          key: cacheKey,
        );
        CalendarImageFileCache.remember(cacheKey, file.file);
      } catch (_) {
        _scheduledKeys.remove(cacheKey);
      }
    }
  }
}
