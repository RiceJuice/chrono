import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Ergebnis einer nativen Dateiauswahl inkl. Originaldateiname für die Anzeige.
class EventPickedFile {
  const EventPickedFile({
    required this.file,
    required this.displayName,
  });

  final File file;
  final String displayName;
}

/// Native Dateiauswahl für Termin-Anhänge (file_picker + iOS-Workarounds).
abstract final class EventAttachmentPicker {
  EventAttachmentPicker._();

  /// iOS: [FilePicker] aus einem Flutter-Modal-Sheet heraus blockiert oft Touch-Events.
  static bool get mustDismissParentSheetBeforePick =>
      !kIsWeb && Platform.isIOS;

  static const Duration iosSheetDismissDelay = Duration(milliseconds: 400);

  static Future<EventPickedFile?> pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: false,
        allowMultiple: false,
        type: FileType.any,
      );
      if (result == null || result.files.isEmpty) return null;
      final platformFile = result.files.single;
      final file = await _fileFromPlatformFile(platformFile);
      if (file == null) return null;
      return EventPickedFile(
        file: file,
        displayName: displayNameForPlatformFile(platformFile),
      );
    } catch (e, stack) {
      debugPrint('[EventAttach] file picker failed: $e\n$stack');
      rethrow;
    }
  }

  static EventPickedFile? fromXFile(XFile? file) {
    if (file == null) return null;
    final path = file.path;
    if (path.isEmpty) return null;
    final name = file.name.trim();
    return EventPickedFile(
      file: File(path),
      displayName: name.isNotEmpty ? name : p.basename(path),
    );
  }

  static String displayNameForPlatformFile(PlatformFile platformFile) {
    final name = platformFile.name.trim();
    if (name.isNotEmpty) return name;
    final path = platformFile.path;
    if (path != null && path.isNotEmpty) return p.basename(path);
    return 'datei_${DateTime.now().microsecondsSinceEpoch}';
  }

  static Future<File> persistPickedFile(
    File source, {
    required String displayName,
  }) async {
    final dir = await getTemporaryDirectory();
    final ext = p.extension(source.path);
    final baseName = _safeBaseName(p.basenameWithoutExtension(displayName));
    final fileName = ext.isNotEmpty ? '$baseName$ext' : _safeFileName(displayName);
    final destPath = p.join(dir.path, fileName);
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

  static String displayNameForFile(String path) => p.basename(path);

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
    final trimmed = p.basename(name.trim());
    if (trimmed.isEmpty) {
      return 'datei_${DateTime.now().microsecondsSinceEpoch}';
    }
    final sanitized = trimmed.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    return sanitized.isNotEmpty
        ? sanitized
        : 'datei_${DateTime.now().microsecondsSinceEpoch}';
  }

  static String _safeBaseName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'datei';
    final sanitized = trimmed.replaceAll(RegExp(r'[^\w\-.]+'), '_');
    return sanitized.length > 80 ? sanitized.substring(0, 80) : sanitized;
  }
}
