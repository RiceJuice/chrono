import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class CalendarEventSourceUploadException implements Exception {
  CalendarEventSourceUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Lädt Quelldateien (Bilder/Dokumente) in den Supabase-Bucket [uploads].
///
/// Die serverseitige Verarbeitung startet, sobald die Datei im Bucket liegt.
class CalendarEventSourceUploadService {
  CalendarEventSourceUploadService({
    SupabaseClient? supabase,
    this.bucket = 'uploads',
    this.maxBytes = 20 * 1024 * 1024,
  }) : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;
  final String bucket;
  final int maxBytes;

  Future<String> uploadSourceFile({required File file}) async {
    final userId = _requireUserId();
    if (!await file.exists()) {
      throw CalendarEventSourceUploadException(
        'Die Datei ist nicht mehr verfügbar. Bitte erneut auswählen.',
      );
    }

    final length = await file.length();
    if (length == 0) {
      throw CalendarEventSourceUploadException('Die Datei ist leer.');
    }
    if (length > maxBytes) {
      throw CalendarEventSourceUploadException(
        'Die Datei ist zu groß (max. ${maxBytes ~/ (1024 * 1024)} MB).',
      );
    }

    final extension = _normalizeExtension(p.extension(file.path));
    final safeName = _safeBaseName(p.basenameWithoutExtension(file.path));
    // Flach im Bucket-Root (kein User-/Unterordner); userId nur zur Auth + im Dateinamen.
    final objectName =
        '$userId-'
        '${DateTime.now().toUtc().millisecondsSinceEpoch}-'
        '${DateTime.now().microsecondsSinceEpoch}-$safeName$extension';
    final storagePath = objectName;

    debugPrint(
      '[EventSourceUpload] start bucket=$bucket path=$storagePath '
      'bytes=$length local=${file.path}',
    );

    final result = await _uploadBytes(storagePath: storagePath, file: file);

    debugPrint('[EventSourceUpload] ok path=$result');

    return result;
  }

  String _requireUserId() {
    final session = _supabase.auth.currentSession;
    final userId = session?.user.id ?? _supabase.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw CalendarEventSourceUploadException(
        'Bitte erneut anmelden, um Dateien hochzuladen.',
      );
    }
    if (session != null && session.isExpired) {
      throw CalendarEventSourceUploadException(
        'Deine Sitzung ist abgelaufen. Bitte erneut anmelden.',
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
      debugPrint(
        '[EventSourceUpload] StorageException '
        'status=${e.statusCode} message=${e.message} error=${e.error}',
      );
      throw CalendarEventSourceUploadException(_mapStorageError(e));
    } catch (e, stack) {
      debugPrint('[EventSourceUpload] unexpected: $e\n$stack');
      rethrow;
    }

    return storagePath;
  }

  String _mapStorageError(StorageException e) {
    final code = e.statusCode?.toString();
    if (code == '403') {
      return 'Keine Berechtigung zum Hochladen. Bitte erneut anmelden oder Admin kontaktieren.';
    }
    if (code == '404') {
      return 'Speicher-Bucket „$bucket“ nicht gefunden. Bitte Admin kontaktieren.';
    }
    final msg = e.message.trim();
    if (msg.isNotEmpty) return msg;
    return 'Upload fehlgeschlagen.';
  }

  String _normalizeExtension(String ext) {
    final lower = ext.toLowerCase();
    if (lower.isEmpty) return '.bin';
    return lower.startsWith('.') ? lower : '.$lower';
  }

  String _safeBaseName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'datei';
    final sanitized = trimmed.replaceAll(RegExp(r'[^\w\-.]+'), '_');
    return sanitized.length > 80 ? sanitized.substring(0, 80) : sanitized;
  }
}
