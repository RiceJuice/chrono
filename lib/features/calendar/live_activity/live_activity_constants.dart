/// App Group für iOS Live Activities (Runner + Widget Extension).
const String kLiveActivityAppGroupId = 'group.com.domspatzen.chronoapp';

/// URL-Scheme für Deep Links aus der Live Activity.
const String kLiveActivityUrlScheme = 'chronoapp';

/// Host für den Deep Link in den Ablaufplan eines Termins.
const String kLiveActivityScheduleDeepLinkHost = 'schedule';

/// Stable Activity-ID pro Kalendertermin.
String liveActivityCustomIdForEvent(String eventId) => 'event_$eventId';

/// Deep Link, wenn die Nutzer:in die Live Activity antippt.
String scheduleLiveActivityDeepLinkForEvent(String eventId) {
  return '$kLiveActivityUrlScheme://$kLiveActivityScheduleDeepLinkHost'
      '?eventId=${Uri.encodeQueryComponent(eventId)}';
}

/// Liest die Event-ID aus einem Ablaufplan-Deep-Link.
String? parseScheduleLiveActivityEventId(Uri uri) {
  final eventId = uri.queryParameters['eventId']?.trim();
  if (eventId == null || eventId.isEmpty) return null;

  if (uri.scheme == kLiveActivityUrlScheme &&
      uri.host == kLiveActivityScheduleDeepLinkHost) {
    return eventId;
  }

  if (uri.path == '/schedule' || uri.path == 'schedule') {
    return eventId;
  }

  if (uri.host == kLiveActivityScheduleDeepLinkHost && uri.path.isEmpty) {
    return eventId;
  }

  return null;
}

/// True, wenn die URI ein Ablaufplan-Deep-Link ist (inkl. GoRouter-Pfadform).
bool isScheduleLiveActivityDeepLink(Uri uri) =>
    parseScheduleLiveActivityEventId(uri) != null;
