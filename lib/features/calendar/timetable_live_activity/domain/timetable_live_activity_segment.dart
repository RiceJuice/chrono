import 'dart:convert';

import 'package:chronoapp/features/calendar/data/subject_color_codec.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:flutter/material.dart';

/// Ein Segment im Tages-Stundenplan (Unterricht oder Mittagessen).
class TimetableLiveActivitySegment {
  const TimetableLiveActivitySegment({
    required this.id,
    required this.type,
    required this.title,
    required this.shortTitle,
    required this.subtitle,
    required this.startMs,
    required this.endMs,
    required this.accentColorHex,
    this.imageUrl,
  });

  final String id;
  final CalendarEntryType type;
  final String title;
  final String shortTitle;
  final String subtitle;
  final int startMs;
  final int endMs;
  final String accentColorHex;
  final String? imageUrl;

  bool get isMeal => type == CalendarEntryType.meal;
  bool get isLesson => type == CalendarEntryType.lesson;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'shortTitle': shortTitle,
      'subtitle': subtitle,
      'startMs': startMs,
      'endMs': endMs,
      'accentColor': accentColorHex,
      if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
    };
  }

  static TimetableLiveActivitySegment? fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    final typeRaw = json['type']?.toString();
    final title = json['title']?.toString() ?? '';
    final startMs = (json['startMs'] as num?)?.toInt();
    final endMs = (json['endMs'] as num?)?.toInt();
    if (id == null || typeRaw == null || startMs == null || endMs == null) {
      return null;
    }

    CalendarEntryType? type;
    for (final candidate in CalendarEntryType.values) {
      if (candidate.name == typeRaw) {
        type = candidate;
        break;
      }
    }
    if (type == null) return null;

    final accent = json['accentColor']?.toString() ?? '#124E30';
    return TimetableLiveActivitySegment(
      id: id,
      type: type,
      title: title,
      shortTitle: json['shortTitle']?.toString() ??
          _fallbackShortTitle(title),
      subtitle: json['subtitle']?.toString() ?? '',
      startMs: startMs,
      endMs: endMs,
      accentColorHex: accent,
      imageUrl: json['imageUrl']?.toString(),
    );
  }

  static List<TimetableLiveActivitySegment> decodeList(String rawJson) {
    if (rawJson.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => TimetableLiveActivitySegment.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .whereType<TimetableLiveActivitySegment>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static String encodeList(List<TimetableLiveActivitySegment> segments) {
    return jsonEncode(segments.map((s) => s.toJson()).toList());
  }

  static String accentHexFor(Color color) => SubjectColorCodec.toHex(color);

  static String _fallbackShortTitle(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.length <= 3) return trimmed;
    return trimmed.substring(0, 3);
  }
}
