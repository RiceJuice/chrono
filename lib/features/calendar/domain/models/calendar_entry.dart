import 'package:flutter/material.dart';
import '../../../../core/database/backend_enums.dart';

enum CalendarEntryType { lesson, meal, event, choir }

class CalendarEntry {
  final String id;
  final String eventName;
  final String? description;
  final String? note;
  final String? location;
  final DateTime startTime;
  final DateTime endTime;
  final List<String>? imageUrls;
  final Color accentColor;
  final CalendarEntryType type;
  final BackendChoir choir;
  final BackendVoice voice;
  final List<BackendVoice> voices;
  final BackendSchoolTrack schoolTrack;
  final String? className;
  final List<String>? imagePaths;
  final List<String>? tags;
  final String? userId;
  final String? seriesId;
  final DateTime? recurrenceId;
  final bool isRecurringInstance;

  CalendarEntry({
    required this.id,
    required this.eventName,
    this.description,
    this.note,
    this.location,
    required this.startTime,
    required this.endTime,
    this.imageUrls,
    required this.accentColor,
    required this.type,
    this.choir = BackendChoir.unknown,
    this.voice = BackendVoice.unknown,
    this.voices = const <BackendVoice>[],
    this.schoolTrack = BackendSchoolTrack.unknown,
    this.className,
    this.imagePaths,
    this.tags,
    this.userId,
    this.seriesId,
    this.recurrenceId,
    this.isRecurringInstance = false,
  });

  CalendarEntry copyWith({
    List<String>? imageUrls,
    String? note,
    String? seriesId,
    DateTime? recurrenceId,
    bool? isRecurringInstance,
  }) {
    return CalendarEntry(
      id: id,
      eventName: eventName,
      description: description,
      note: note ?? this.note,
      location: location,
      startTime: startTime,
      endTime: endTime,
      imageUrls: imageUrls ?? this.imageUrls,
      accentColor: accentColor,
      type: type,
      choir: choir,
      voice: voice,
      voices: voices,
      schoolTrack: schoolTrack,
      className: className,
      imagePaths: imagePaths,
      tags: tags,
      userId: userId,
      seriesId: seriesId ?? this.seriesId,
      recurrenceId: recurrenceId ?? this.recurrenceId,
      isRecurringInstance: isRecurringInstance ?? this.isRecurringInstance,
    );
  }
}