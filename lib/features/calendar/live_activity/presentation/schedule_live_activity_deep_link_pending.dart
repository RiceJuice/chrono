/// Zwischenspeicher für Ablaufplan-Deep-Links bis die Kalenderseite bereit ist.
abstract final class ScheduleLiveActivityDeepLinkPending {
  ScheduleLiveActivityDeepLinkPending._();

  static String? _eventId;

  static void set(String eventId) {
    final trimmed = eventId.trim();
    if (trimmed.isEmpty) return;
    _eventId = trimmed;
  }

  static String? peek() => _eventId;

  static String? consume() {
    final eventId = _eventId;
    _eventId = null;
    return eventId;
  }
}
