import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class CalendarImageUrlResolver {
  CalendarImageUrlResolver({
    required SupabaseClient supabase,
    this.bucket = 'calendar_images',
    this.signedUrlTtlSeconds = 60 * 60,
  }) : _supabase = supabase;

  final SupabaseClient _supabase;
  final String bucket;
  final int signedUrlTtlSeconds;
  bool _authStateLogged = false;

  Future<List<String>?> resolveSignedUrls(List<String>? imagePaths) async {
    if (imagePaths == null || imagePaths.isEmpty) return null;

    final out = <String>[];
    if (kDebugMode) {
      _logAuthStateOnce();
      debugPrint(
        '[CalendarImageUrlResolver] resolveSignedUrls count=${imagePaths.length} bucket=$bucket',
      );
    }

    for (final rawPath in imagePaths) {
      final candidatePaths = _candidateStoragePaths(rawPath);
      if (candidatePaths.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            '[CalendarImageUrlResolver] Skip invalid path raw="$rawPath"',
          );
        }
        continue;
      }
      String? resolved;
      Object? lastError;

      for (final path in candidatePaths) {
        try {
          final signedUrl = await _supabase.storage
              .from(bucket)
              .createSignedUrl(path, signedUrlTtlSeconds)
              .timeout(const Duration(seconds: 8));
          if (signedUrl.isNotEmpty) {
            resolved = signedUrl;
            break;
          } else if (kDebugMode) {
            debugPrint(
              '[CalendarImageUrlResolver] Empty signed URL for "$path"',
            );
          }
        } catch (e) {
          lastError = e;
          if (kDebugMode) {
            debugPrint(
              '[CalendarImageUrlResolver] Failed candidate="$path" raw="$rawPath": $e',
            );
            await _diagnoseCandidateFailure(path, e);
          }
        }
      }

      if (resolved != null) {
        out.add(resolved);
      } else if (kDebugMode) {
        debugPrint(
          '[CalendarImageUrlResolver] Could not resolve raw="$rawPath" candidates=$candidatePaths lastError=$lastError',
        );
      }
    }

    if (kDebugMode) {
      debugPrint(
        '[CalendarImageUrlResolver] Resolved ${out.length}/${imagePaths.length} URL(s)',
      );
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

  void _logAuthStateOnce() {
    if (_authStateLogged) return;
    _authStateLogged = true;
    final user = _supabase.auth.currentUser;
    final session = _supabase.auth.currentSession;
    debugPrint(
      '[CalendarImageUrlResolver] auth user=${user?.id ?? "null"} session=${session == null ? "none" : "present"}',
    );
  }

  Future<void> _diagnoseCandidateFailure(String path, Object error) async {
    // Zusätzliche Diagnose nur im Debug-Build; hilft zwischen
    // "Pfad falsch" und "Policy/Permissions" zu unterscheiden.
    try {
      final bytes = await _supabase.storage
          .from(bucket)
          .download(path)
          .timeout(const Duration(seconds: 8));
      debugPrint(
        '[CalendarImageUrlResolver][diag] download ok for "$path" bytes=${bytes.length}',
      );
    } catch (downloadError) {
      debugPrint(
        '[CalendarImageUrlResolver][diag] download failed for "$path": $downloadError',
      );
    }

    if (error is StorageException) {
      debugPrint(
        '[CalendarImageUrlResolver][diag] storage status=${error.statusCode} message=${error.message} error=${error.error}',
      );
    }
  }
}
