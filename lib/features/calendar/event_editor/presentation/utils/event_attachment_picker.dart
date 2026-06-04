import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Native Dateiauswahl für Termin-Anhänge (file_picker + iOS-Workarounds).
abstract final class EventAttachmentPicker {
  EventAttachmentPicker._();

  /// iOS: [FilePicker] aus einem Flutter-Modal-Sheet heraus blockiert oft Touch-Events.
  static bool get mustDismissParentSheetBeforePick =>
      !kIsWeb && Platform.isIOS;

  static const Duration iosSheetDismissDelay = Duration(milliseconds: 400);

  static Future<File?> pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: false,
        allowMultiple: false,
        type: FileType.any,
      );
      if (result == null || result.files.isEmpty) return null;
      return _fileFromPlatformFile(result.files.single);
    } catch (e, stack) {
      debugPrint('[EventAttach] file picker failed: $e\n$stack');
      rethrow;
    }
  }

  static Future<File> persistPickedFile(File source) async {
    final dir = await getTemporaryDirectory();
    final ext = p.extension(source.path);
    final destPath = p.join(
      dir.path,
      'chrono_source_${DateTime.now().microsecondsSinceEpoch}$ext',
    );
    final dest = File(destPath);
    await dest.writeAsBytes(await source.readAsBytes(), flush: true);
    return dest;
  }

  static bool isImagePath(String path) {
    final ext = path.split('.').last.toLowerCase();
    return <String>{
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'heic',
      'heif',
    }.contains(ext);
  }

  static bool isPdfPath(String path) {
    return path.split('.').last.toLowerCase() == 'pdf';
  }

  static String displayNameForFile(String path) {
    final parts = path.split(RegExp(r'[/\\]'));
    return parts.isNotEmpty ? parts.last : path;
  }

  static Future<File?> _fileFromPlatformFile(PlatformFile platformFile) async {
    final path = platformFile.path;
    if (path != null && path.isNotEmpty) {
      return File(path);
    }

    final stream = platformFile.readStream;
    if (stream != null) {
      final dir = await getTemporaryDirectory();
      final name = _safeFileName(platformFile.name);
      final dest = File(p.join(dir.path, name));
      await stream.pipe(dest.openWrite());
      return dest;
    }

    final bytes = platformFile.bytes;
    if (bytes != null && bytes.isNotEmpty) {
      final dir = await getTemporaryDirectory();
      final name = _safeFileName(platformFile.name);
      final dest = File(p.join(dir.path, name));
      await dest.writeAsBytes(bytes, flush: true);
      return dest;
    }

    return null;
  }

  static String _safeFileName(String name) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return 'datei_${DateTime.now().microsecondsSinceEpoch}';
  }
}
