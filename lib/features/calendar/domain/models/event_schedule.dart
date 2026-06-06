import '../../../../core/database/backend_enums.dart';

/// Ein Ablaufplanpunkt zu einem Kalendertermin ([event_id]).
class EventSchedule {
  const EventSchedule({
    required this.id,
    required this.eventId,
    required this.title,
    required this.startTime,
    this.description,
    this.endTime,
    this.location,
    this.choirs = const [],
    this.voices = const [],
  });

  final String id;
  final String eventId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime? endTime;
  final String? location;
  final List<BackendChoir> choirs;
  final List<BackendVoice> voices;
}
