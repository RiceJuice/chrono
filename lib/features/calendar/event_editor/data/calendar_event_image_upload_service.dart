import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class CalendarEventImageUploadException implements Exception {
  CalendarEventImageUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Lädt Termin-Bilder/Dateien in den Supabase-Bucket [calendar_images] hoch.
class CalendarEventImageUploadService {
  CalendarEventImageUploadService({
    SupabaseClient? supabase,
    this.bucket = 'calendar_images',
    this.maxBytes = 20 * 1024 * 1024,
  }) : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;
  final String bucket;
  final int maxBytes;

  /// Nach [createStandalone]: Pfad `{userId}/events/{eventId}/…` (RLS am Termin).
  Future<String> uploadFileForEvent({
    required String eventId,
    required File file,
  }) async {
    final userId = _requireUserId();
    final length = await file.length();
    if (length > maxBytes) {
      throw CalendarEventImageUploadException(
        'Die Datei ist zu groß (max. ${maxBytes ~/ (1024 * 1024)} MB).',
      );
    }

    final extension = _normalizeExtension(p.extension(file.path));
    final objectName = _randomObjectName(extension);
    final storagePath = '$userId/events/$eventId/$objectName';
    return _uploadBytes(storagePath: storagePath, file: file);
  }

  String _requireUserId() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw CalendarEventImageUploadException(
        'Bitte erneut anmelden, um Dateien hochzuladen.',
      );
    }
    return userId;
  }

  Future<String> _uploadBytes({
    required String storagePath,
    required File file,
  }) async {
    final bytes = await file.readAsBytes();
    final contentType = lookupMimeType(file.path, headerBytes: bytes) ??
        'application/octet-stream';

    try {
      await _supabase.storage.from(bucket).uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: false,
            ),
          );
    } on StorageException catch (e) {
      throw CalendarEventImageUploadException(
        _mapStorageError(e),
      );
    }

    return storagePath;
  }

  String _mapStorageError(StorageException e) {
    if (e.statusCode == '403') {
      return 'Keine Berechtigung zum Hochladen. Bitte erneut anmelden oder Admin kontaktieren.';
    }
    final msg = e.message.trim();
    if (msg.isNotEmpty) return msg;
    return 'Upload fehlgeschlagen.';
  }

  String _normalizeExtension(String ext) {
    final lower = ext.toLowerCase();
    if (lower.isEmpty) return '.jpg';
    return lower.startsWith('.') ? lower : '.$lower';
  }

  String _randomObjectName(String extension) {
    final stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    return '$stamp-${DateTime.now().microsecondsSinceEpoch}$extension';
  }
}
