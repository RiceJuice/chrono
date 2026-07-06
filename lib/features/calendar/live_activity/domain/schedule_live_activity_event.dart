import '../../../../core/database/backend_enums.dart';

/// Kalendertermin (type event) ohne Ablaufplan für Live-Activity-Zeitplanung.
class ScheduleLiveActivityEvent {
  const ScheduleLiveActivityEvent({
    required this.id,
    required this.eventName,
    required this.startTime,
    required this.endTime,
    this.location,
    this.choirs = const [],
    this.voices = const [],
  });

  final String id;
  final String eventName;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final List<BackendChoir> choirs;
  final List<BackendVoice> voices;
}
