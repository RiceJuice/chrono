import 'package:chronoapp/features/calendar/timetable_live_activity/domain/timetable_live_activity_segment.dart';
import 'package:chronoapp/features/calendar/timetable_live_activity/timetable_live_activity_constants.dart';
import 'package:live_activities/models/live_activity_file.dart';

/// Anzeige-Daten für die Stundenplan-Live-Activity (voller Tagesplan im Payload).
class TimetableLiveActivitySnapshot {
  const TimetableLiveActivitySnapshot({
    required this.dayDateKey,
    required this.customId,
    required this.segments,
    required this.activityStartMs,
    required this.dayEndMs,
    required this.currentIndex,
    required this.currentTitle,
    required this.currentSubtitle,
    required this.hasNext,
    required this.nextTitle,
    required this.nextSubtitle,
    required this.segmentStartMs,
    required this.segmentEndMs,
    required this.accentColorHex,
    required this.isMeal,
    required this.imageUrl,
    required this.remainingLessons,
    required this.isPreStart,
  });

  final String dayDateKey;
  final String customId;
  final List<TimetableLiveActivitySegment> segments;
  final int activityStartMs;
  final int dayEndMs;
  final int currentIndex;
  final String currentTitle;
  final String currentSubtitle;
  final bool hasNext;
  final String nextTitle;
  final String nextSubtitle;
  final int segmentStartMs;
  final int segmentEndMs;
  final String accentColorHex;
  final bool isMeal;
  final String imageUrl;
  final int remainingLessons;
  final bool isPreStart;

  TimetableLiveActivitySegment? get currentSegment {
    if (currentIndex < 0 || currentIndex >= segments.length) return null;
    return segments[currentIndex];
  }

  String get contentFingerprint =>
      '$dayDateKey|${TimetableLiveActivitySegment.encodeList(segments)}|'
      '$currentIndex|$segmentStartMs|$segmentEndMs|$remainingLessons';

  Map<String, dynamic> toActivityPayload() {
    final payload = <String, dynamic>{
      'kind': kTimetableLiveActivityKind,
      'dayDate': dayDateKey,
      'segmentsJson': TimetableLiveActivitySegment.encodeList(segments),
      'activityStartMs': activityStartMs,
      'dayEndMs': dayEndMs,
      'remainingLessons': remainingLessons,
      'currentIndex': currentIndex,
      'currentTitle': currentTitle,
      'currentSubtitle': currentSubtitle,
      'hasNext': hasNext,
      'nextTitle': nextTitle,
      'nextSubtitle': nextSubtitle,
      'segmentStartMs': segmentStartMs,
      'segmentEndMs': segmentEndMs,
      'accentColor': accentColorHex,
      'isMeal': isMeal,
      'imageUrl': imageUrl,
      'eventId': dayDateKey,
      'isPreStart': isPreStart,
    };
    if (isMeal && imageUrl.isNotEmpty) {
      payload['mealImage'] = LiveActivityFileFromUrl.image(
        imageUrl,
        imageOptions: LiveActivityImageFileOptions(resizeFactor: 0.4),
      );
    }
    return payload;
  }
}
