import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'calendar_image_cache_manager.dart';

abstract final class CalendarImageFileCache {
  static final Map<String, File> _memory = {};

  static File? peek(String cacheKey) {
    final cached = _memory[cacheKey];
    if (cached == null) return null;
    if (!cached.existsSync()) {
      _memory.remove(cacheKey);
      return null;
    }
    return cached;
  }

  static void remember(String cacheKey, File file) {
    _memory[cacheKey] = file;
  }

  static Future<File?> resolve(String cacheKey) async {
    final fromMemory = peek(cacheKey);
    if (fromMemory != null) return fromMemory;

    final FileInfo? info = await CalendarImageCacheManager.instance
        .getFileFromCache(cacheKey);
    if (info == null) return null;

    remember(cacheKey, info.file);
    return info.file;
  }
}
