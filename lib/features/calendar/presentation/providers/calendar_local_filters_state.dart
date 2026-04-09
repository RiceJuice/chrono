part of 'calendar_providers.dart';

class CalendarLocalFilters {
  const CalendarLocalFilters({
    this.choir,
    this.voice,
    this.className,
    this.profileChoir,
    this.profileVoice,
    this.profileClassName,
    this.hasInitializedFromProfile = false,
    this.hasUserOverrides = false,
  });

  final String? choir;
  final String? voice;
  final String? className;
  final String? profileChoir;
  final String? profileVoice;
  final String? profileClassName;
  final bool hasInitializedFromProfile;
  final bool hasUserOverrides;

  CalendarLocalFilters copyWith({
    String? choir,
    String? voice,
    String? className,
    String? profileChoir,
    String? profileVoice,
    String? profileClassName,
    bool? hasInitializedFromProfile,
    bool? hasUserOverrides,
  }) {
    return CalendarLocalFilters(
      choir: choir,
      voice: voice,
      className: className,
      profileChoir: profileChoir ?? this.profileChoir,
      profileVoice: profileVoice ?? this.profileVoice,
      profileClassName: profileClassName ?? this.profileClassName,
      hasInitializedFromProfile:
          hasInitializedFromProfile ?? this.hasInitializedFromProfile,
      hasUserOverrides: hasUserOverrides ?? this.hasUserOverrides,
    );
  }
}

class CalendarLocalFiltersNotifier extends fr.Notifier<CalendarLocalFilters> {
  @override
  CalendarLocalFilters build() => const CalendarLocalFilters();

  void initializeFromProfile(ProfileSnapshot? profile) {
    final normalizedProfileChoir = _normalizeText(profile?.choir);
    final normalizedProfileVoice = _normalizeText(profile?.voice);
    final normalizedProfileClass = _normalizeText(profile?.className);

    if (!state.hasInitializedFromProfile || !state.hasUserOverrides) {
      state = state.copyWith(
        choir: normalizedProfileChoir,
        voice: normalizedProfileVoice,
        className: normalizedProfileClass,
        profileChoir: normalizedProfileChoir,
        profileVoice: normalizedProfileVoice,
        profileClassName: normalizedProfileClass,
        hasInitializedFromProfile: true,
        hasUserOverrides: false,
      );
      return;
    }

    state = state.copyWith(
      choir: state.choir,
      voice: state.voice,
      className: state.className,
      profileChoir: normalizedProfileChoir,
      profileVoice: normalizedProfileVoice,
      profileClassName: normalizedProfileClass,
      hasInitializedFromProfile: true,
    );
  }

  void setChoir(String? value) {
    state = state.copyWith(
      choir: _normalizeText(value),
      voice: state.voice,
      className: state.className,
      hasUserOverrides: true,
    );
  }

  void setVoice(String? value) {
    state = state.copyWith(
      choir: state.choir,
      voice: _normalizeText(value),
      className: state.className,
      hasUserOverrides: true,
    );
  }

  void setClassName(String? value) {
    state = state.copyWith(
      choir: state.choir,
      voice: state.voice,
      className: _normalizeText(value),
      hasUserOverrides: true,
    );
  }

  void resetToProfileDefaults() {
    state = state.copyWith(
      choir: state.profileChoir,
      voice: state.profileVoice,
      className: state.profileClassName,
      hasUserOverrides: false,
    );
  }
}

final calendarLocalFiltersProvider = fr.NotifierProvider<
    CalendarLocalFiltersNotifier,
    CalendarLocalFilters
  >(CalendarLocalFiltersNotifier.new);
