import 'package:supabase_flutter/supabase_flutter.dart';

import 'calendar_signed_url_cache.dart';

class CalendarImageUrlResolver {
  CalendarImageUrlResolver({
    required SupabaseClient supabase,
    this.bucket = 'calendar_images',
    this.signedUrlTtlSeconds = 60 * 60,
    CalendarSignedUrlCache? signedUrlCache,
  }) : _supabase = supabase,
       _signedUrlCache = signedUrlCache ?? CalendarSignedUrlCache.shared;

  final SupabaseClient _supabase;
  final String bucket;
  final int signedUrlTtlSeconds;
  final CalendarSignedUrlCache _signedUrlCache;

  final Map<String, Future<String?>> _inFlightByPath = {};

  Duration get _signedUrlTtl => Duration(seconds: signedUrlTtlSeconds);

  /// Liefert bereits gecachte URLs synchron (nach [CalendarSignedUrlCache.ensureLoaded]).
  List<String>? peekResolvedUrls(List<String>? imagePaths) {
    if (imagePaths == null || imagePaths.isEmpty) return null;

    final out = <String>[];
    for (final rawPath in imagePaths) {
      final candidatePaths = _candidateStoragePaths(rawPath);
      String? cached;
      for (final path in candidatePaths) {
        cached = _signedUrlCache.peek(path);
        if (cached != null) break;
      }
      if (cached == null) return null;
      out.add(cached);
    }
    return out.isEmpty ? null : out;
  }

  Future<List<String>?> resolveSignedUrls(List<String>? imagePaths) async {
    if (imagePaths == null || imagePaths.isEmpty) return null;

    await _signedUrlCache.ensureLoaded();

    final cached = peekResolvedUrls(imagePaths);
    if (cached != null) return cached;

    final out = <String>[];

    for (final rawPath in imagePaths) {
      final candidatePaths = _candidateStoragePaths(rawPath);
      if (candidatePaths.isEmpty) continue;

      String? resolved;
      for (final path in candidatePaths) {
        resolved = _signedUrlCache.peek(path);
        if (resolved != null) break;
      }

      resolved ??= await _resolvePathWithCache(candidatePaths);
      if (resolved != null) {
        out.add(resolved);
      }
    }
    return out.isEmpty ? null : out;
  }

  Future<String?> _resolvePathWithCache(List<String> candidatePaths) async {
    for (final path in candidatePaths) {
      final cached = _signedUrlCache.peek(path);
      if (cached != null) return cached;

      final inFlight = _inFlightByPath[path];
      if (inFlight != null) {
        final result = await inFlight;
        if (result != null) return result;
        continue;
      }

      final future = _fetchSignedUrl(path);
      _inFlightByPath[path] = future;
      try {
        final signedUrl = await future;
        if (signedUrl != null) return signedUrl;
      } finally {
        _inFlightByPath.remove(path);
      }
    }
    return null;
  }

  Future<String?> _fetchSignedUrl(String path) async {
    try {
      final signedUrl = await _supabase.storage
          .from(bucket)
          .createSignedUrl(path, signedUrlTtlSeconds)
          .timeout(const Duration(seconds: 8));
      if (signedUrl.isEmpty) return null;

      _signedUrlCache.put(
        storagePath: path,
        signedUrl: signedUrl,
        ttl: _signedUrlTtl,
      );
      return signedUrl;
    } catch (_) {
      return null;
    }
  }

  List<String> _candidateStoragePaths(String rawPath) {
    var path = rawPath.trim();
    if (path.isEmpty) return const [];

    path = path.replaceAll('\\', '/');
    while (path.startsWith('/')) {
      path = path.substring(1);
    }

    final bucketPrefix = '$bucket/';
    final originalSanitized = path;

    if (path.startsWith(bucketPrefix)) {
      path = path.substring(bucketPrefix.length);
    }
    final withoutBucketPrefix = path;

    // Falls versehentlich eine komplette URL gespeichert wurde.
    final marker = '/object/sign/$bucket/';
    final markerIndex = originalSanitized.indexOf(marker);
    if (markerIndex >= 0) {
      final extracted = originalSanitized.substring(markerIndex + marker.length);
      final withExtracted = extracted.startsWith('/')
          ? extracted.substring(1)
          : extracted;
      return _uniqueNonEmpty(<String>[withExtracted]);
    }

    return _uniqueNonEmpty(<String>[
      withoutBucketPrefix,
      originalSanitized,
    ]);
  }

  List<String> _uniqueNonEmpty(List<String> values) {
    final out = <String>[];
    final seen = <String>{};
    for (final value in values) {
      final normalized = value.trim();
      if (normalized.isEmpty || seen.contains(normalized)) continue;
      seen.add(normalized);
      out.add(normalized);
    }
    return out;
  }
}
