/// Anzeige-Daten für eine laufende Ablaufplan-Live-Activity.
class ScheduleLiveActivitySnapshot {
  const ScheduleLiveActivitySnapshot({
    required this.eventId,
    required this.customId,
    required this.currentScheduleId,
    required this.currentTitle,
    required this.currentSubtitle,
    required this.hasNext,
    required this.nextTitle,
    required this.nextSubtitle,
    required this.segmentStartMs,
    required this.segmentEndMs,
  });

  final String eventId;
  final String customId;
  final String currentScheduleId;
  final String currentTitle;
  final String currentSubtitle;
  final bool hasNext;
  final String nextTitle;
  final String nextSubtitle;
  final int segmentStartMs;
  final int segmentEndMs;

  double progressAt(DateTime now) {
    final start = segmentStartMs;
    final end = segmentEndMs;
    if (end <= start) return 1;
    final nowMs = now.millisecondsSinceEpoch;
    if (nowMs <= start) return 0;
    if (nowMs >= end) return 1;
    return (nowMs - start) / (end - start);
  }

  /// Verbleibende Sekunden bis Segmentende (Countdown läuft nativ im Widget).
  int remainingSecondsAt(DateTime now) {
    final endMs = segmentEndMs;
    final nowMs = now.millisecondsSinceEpoch;
    final seconds = ((endMs - nowMs) / 1000).ceil();
    if (seconds <= 0) return 0;
    return seconds;
  }

  /// Verbleibende Minuten (abgerundet aus Sekunden).
  int remainingMinutesAt(DateTime now) {
    final seconds = remainingSecondsAt(now);
    if (seconds <= 0) return 0;
    return (seconds + 59) ~/ 60;
  }

  Map<String, dynamic> toActivityPayload() {
    return {
      'currentTitle': currentTitle,
      'currentSubtitle': currentSubtitle,
      'hasNext': hasNext,
      'nextTitle': nextTitle,
      'nextSubtitle': nextSubtitle,
      'segmentStartMs': segmentStartMs,
      'segmentEndMs': segmentEndMs,
      'eventId': eventId,
    };
  }

  /// Fingerabdruck für Inhaltsänderungen (Titel, Zeiten, nächstes Segment).
  String get contentFingerprint =>
      '$currentScheduleId|$currentTitle|$currentSubtitle|$hasNext|'
      '$nextTitle|$nextSubtitle|$segmentStartMs|$segmentEndMs';
}
