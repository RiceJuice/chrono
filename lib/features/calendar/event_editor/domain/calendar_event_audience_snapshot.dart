import '../../../../core/database/backend_enums.dart';
import 'calendar_event_form_state.dart';

/// Zielgruppen-Zuordnung eines Termins für Push-Broadcast (serialisierbar).
class CalendarEventAudienceSnapshot {
  const CalendarEventAudienceSnapshot({
    this.choir,
    this.voices = const <String>[],
    this.schoolTrack,
    this.className,
    this.diet,
  });

  final String? choir;
  final List<String> voices;
  final String? schoolTrack;
  final String? className;
  final String? diet;

  factory CalendarEventAudienceSnapshot.fromFormState(
    CalendarEventFormState state,
  ) {
    final voiceLabels = state.voices
        .where((v) => v != BackendVoice.unknown)
        .map((v) => v.displayLabel)
        .toList();
    return CalendarEventAudienceSnapshot(
      choir: state.choir == BackendChoir.unknown ? null : state.choir.displayLabel,
      voices: voiceLabels,
      schoolTrack: state.schoolTrack == BackendSchoolTrack.unknown
          ? null
          : state.schoolTrack.displayLabel,
      className: _nullableTrim(state.className),
      diet: state.diet == BackendDiet.unknown ? null : state.diet.displayLabel,
    );
  }

  bool get isEmpty =>
      choir == null &&
      voices.isEmpty &&
      schoolTrack == null &&
      className == null &&
      diet == null;

  bool sameAs(CalendarEventAudienceSnapshot other) {
    return choir == other.choir &&
        _listEquals(voices, other.voices) &&
        schoolTrack == other.schoolTrack &&
        className == other.className &&
        diet == other.diet;
  }

  Map<String, dynamic> toJson() {
    return {
      if (choir != null) 'choir': choir,
      'voices': voices,
      if (schoolTrack != null) 'schooltrack': schoolTrack,
      if (className != null) 'class_name': className,
      if (diet != null) 'diet': diet,
    };
  }

  static String? _nullableTrim(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
