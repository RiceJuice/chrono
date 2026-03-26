import 'package:flutter/material.dart';

enum CalendarEntryType { lesson, meal, event, chor }

class CalendarEntry {
  final String id;
  final String title;
  final String? subtitle;
  final String? location;
  final DateTime startTime;
  final DateTime endTime;
  final String? imageUrl;
  final Color accentColor;
  final CalendarEntryType type;
  final List<String>? tags;

  CalendarEntry({
    required this.id,
    required this.title,
    this.subtitle,
    this.location,
    required this.startTime,
    required this.endTime,
    this.imageUrl,
    required this.accentColor,
    required this.type,
    this.tags,
  });
}