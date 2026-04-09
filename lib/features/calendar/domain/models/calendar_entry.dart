import 'package:flutter/material.dart';
import '../../../../core/database/backend_enums.dart';

enum CalendarEntryType { lesson, meal, event, choir }

class CalendarEntry {
  final String id;
  final String eventName;
  final String? description;
  final String? location;
  final DateTime startTime;
  final DateTime endTime;
  final List<String>? imageUrls;
  final Color accentColor;
  final CalendarEntryType type;
  final BackendChoir choir;
  final BackendVoice voice;
  final BackendSchoolTrack schoolTrack;
  final String? className;
  final List<String>? imagePaths;
  final List<String>? tags;
  final String? userId;

  CalendarEntry({
    required this.id,
    required this.eventName,
    this.description,
    this.location,
    required this.startTime,
    required this.endTime,
    this.imageUrls,
    required this.accentColor,
    required this.type,
    this.choir = BackendChoir.unknown,
    this.voice = BackendVoice.unknown,
    this.schoolTrack = BackendSchoolTrack.unknown,
    this.className,
    this.imagePaths,
    this.tags,
    this.userId,
  });

  CalendarEntry copyWith({
    List<String>? imageUrls,
  }) {
    return CalendarEntry(
      id: id,
      eventName: eventName,
      description: description,
      location: location,
      startTime: startTime,
      endTime: endTime,
      imageUrls: imageUrls ?? this.imageUrls,
      accentColor: accentColor,
      type: type,
      choir: choir,
      voice: voice,
      schoolTrack: schoolTrack,
      className: className,
      imagePaths: imagePaths,
      tags: tags,
      userId: userId,
    );
  }
}