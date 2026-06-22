/// App Group für iOS Live Activities (Runner + Widget Extension).
const String kLiveActivityAppGroupId = 'group.com.domspatzen.chronoapp';

/// URL-Scheme für Deep Links aus der Live Activity.
const String kLiveActivityUrlScheme = 'chronoapp';

/// Stable Activity-ID pro Kalendertermin.
String liveActivityCustomIdForEvent(String eventId) => 'event_$eventId';
