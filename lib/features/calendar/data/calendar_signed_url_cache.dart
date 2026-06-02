import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Speichert signierte Supabase-Storage-URLs nach Storage-Pfad.
///
/// Verhindert wiederholte [createSignedUrl]-Aufrufe beim Scrollen und hält
/// gültige URLs über App-Neustarts (JSON im Application-Support-Verzeichnis).
class CalendarSignedUrlCache {
  CalendarSignedUrlCache({
    this.refreshBeforeExpiry = const Duration(minutes: 10),
  });

  final Duration refreshBeforeExpiry;

  final Map<String, _SignedUrlEntry> _memory = {};
  Future<void>? _loadFuture;

  static final CalendarSignedUrlCache shared = CalendarSignedUrlCache();

  Future<void> ensureLoaded() {
    _loadFuture ??= _loadFromDisk();
    return _loadFuture!;
  }

  String? peek(String storagePath) {
    final key = _normalizeKey(storagePath);
    final entry = _memory[key];
    if (entry == null || entry.isStale(refreshBeforeExpiry)) return null;
    return entry.url;
  }

  void put({
    required String storagePath,
    required String signedUrl,
    required Duration ttl,
  }) {
    final key = _normalizeKey(storagePath);
    _memory[key] = _SignedUrlEntry(
      url: signedUrl,
      expiresAt: DateTime.now().add(ttl),
    );
    _schedulePersist();
  }

  String _normalizeKey(String storagePath) => storagePath.trim();

  Future<File> _cacheFile() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'calendar_signed_urls.json'));
  }

  Future<void> _loadFromDisk() async {
    try {
      final file = await _cacheFile();
      if (!await file.exists()) return;

      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) return;

      final now = DateTime.now();
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is! Map<String, dynamic>) continue;
        final url = value['url'];
        final expiresAtMs = value['expiresAtMs'];
        if (url is! String || expiresAtMs is! num) continue;

        final expiresAt = DateTime.fromMillisecondsSinceEpoch(
          expiresAtMs.toInt(),
        );
        if (!expiresAt.isAfter(now)) continue;

        _memory[entry.key] = _SignedUrlEntry(url: url, expiresAt: expiresAt);
      }
    } catch (_) {
      // Beschädigter Cache — beim nächsten Schreiben neu aufgebaut.
    }
  }

  Future<void>? _persistFuture;

  void _schedulePersist() {
    _persistFuture ??= _persistToDisk().whenComplete(() {
      _persistFuture = null;
    });
  }

  Future<void> _persistToDisk() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    try {
      final file = await _cacheFile();
      final payload = <String, dynamic>{};
      final now = DateTime.now();

      for (final entry in _memory.entries) {
        if (!entry.value.expiresAt.isAfter(now)) continue;
        payload[entry.key] = {
          'url': entry.value.url,
          'expiresAtMs': entry.value.expiresAt.millisecondsSinceEpoch,
        };
      }

      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(payload));
    } catch (_) {
      // Persistenz ist optional — Speicher-Cache bleibt aktiv.
    }
  }
}

class _SignedUrlEntry {
  const _SignedUrlEntry({required this.url, required this.expiresAt});

  final String url;
  final DateTime expiresAt;

  bool isStale(Duration refreshBeforeExpiry) {
    return !expiresAt.isAfter(DateTime.now().add(refreshBeforeExpiry));
  }
}
