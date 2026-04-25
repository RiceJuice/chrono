import 'package:supabase_flutter/supabase_flutter.dart';

class CalendarImageUrlResolver {
  CalendarImageUrlResolver({
    required SupabaseClient supabase,
    this.bucket = 'calendar_images',
    this.signedUrlTtlSeconds = 60 * 60,
  }) : _supabase = supabase;

  final SupabaseClient _supabase;
  final String bucket;
  final int signedUrlTtlSeconds;

  Future<List<String>?> resolveSignedUrls(List<String>? imagePaths) async {
    if (imagePaths == null || imagePaths.isEmpty) return null;

    final out = <String>[];

    for (final rawPath in imagePaths) {
      final candidatePaths = _candidateStoragePaths(rawPath);
      if (candidatePaths.isEmpty) continue;
      String? resolved;

      for (final path in candidatePaths) {
        try {
          final signedUrl = await _supabase.storage
              .from(bucket)
              .createSignedUrl(path, signedUrlTtlSeconds)
              .timeout(const Duration(seconds: 8));
          if (signedUrl.isNotEmpty) {
            resolved = signedUrl;
            break;
          }
        } catch (_) {
        }
      }

      if (resolved != null) {
        out.add(resolved);
      }
    }
    return out.isEmpty ? null : out;
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
      final withExtracted = extracted.startsWith('/') ? extracted.substring(1) : extracted;
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
