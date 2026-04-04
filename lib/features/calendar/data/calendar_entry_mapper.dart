import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sqlite3/common.dart' as sqlite;

import '../domain/models/calendar_entry.dart';

class CalendarEntryMapper {
  CalendarEntryMapper._();

  static CalendarEntry fromRow(sqlite.Row row) {
    final typeStr = row['type'] as String?;
    final accent = _asInt(row['accent_color']);

    return CalendarEntry(
      id: row['id'].toString(),
      title: (row['title'] as String?) ?? '',
      subtitle: row['subtitle'] as String?,
      location: row['location'] as String?,
      startTime: _parseDateTime(row['start_time']),
      endTime: _parseDateTime(row['end_time']),
      imageUrls: _decodeStringList(_asString(row['image_urls'])),
      accentColor: Color(accent ?? 0xFF2196F3),
      type: _parseType(typeStr),
      tags: _decodeStringList(_asString(row['tags'])),
      userId: _asString(row['user_id']),
    );
  }

  static String? _asString(Object? value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  static int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime _parseDateTime(Object? value) {
    final s = _asString(value);
    if (s == null || s.isEmpty) {
      throw FormatException('start/end_time fehlt oder leer');
    }
    final normalized = s.contains('T') ? s : s.replaceFirst(' ', 'T');
    return DateTime.parse(normalized);
  }

  static CalendarEntryType _parseType(String? raw) {
    return switch (raw) {
      'lesson' => CalendarEntryType.lesson,
      'meal' => CalendarEntryType.meal,
      'event' => CalendarEntryType.event,
      'chor' => CalendarEntryType.chor,
      _ => CalendarEntryType.event,
    };
  }

  static List<String>? _decodeStringList(String? json) {
    if (json == null || json.isEmpty) return null;
    final decoded = jsonDecode(json);
    if (decoded is! List) return null;
    return decoded.map((e) => e.toString()).toList();
  }
}
