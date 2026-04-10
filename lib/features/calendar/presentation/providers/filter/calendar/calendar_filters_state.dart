class CalendarFiltersState {
  const CalendarFiltersState({
    this.choirs = const <String>[],
    this.voices = const <String>[],
    this.classNames = const <String>[],
    this.defaultChoirs = const <String>[],
    this.defaultVoices = const <String>[],
    this.defaultClassNames = const <String>[],
    this.hasInitializedDefaults = false,
    this.hasUserOverrides = false,
  });

  final List<String> choirs;
  final List<String> voices;
  final List<String> classNames;
  final List<String> defaultChoirs;
  final List<String> defaultVoices;
  final List<String> defaultClassNames;
  final bool hasInitializedDefaults;
  final bool hasUserOverrides;

  bool get hasActiveFilters =>
      choirs.isNotEmpty || voices.isNotEmpty || classNames.isNotEmpty;

  CalendarFiltersState copyWith({
    List<String>? choirs,
    List<String>? voices,
    List<String>? classNames,
    List<String>? defaultChoirs,
    List<String>? defaultVoices,
    List<String>? defaultClassNames,
    bool? hasInitializedDefaults,
    bool? hasUserOverrides,
  }) {
    return CalendarFiltersState(
      choirs: choirs ?? this.choirs,
      voices: voices ?? this.voices,
      classNames: classNames ?? this.classNames,
      defaultChoirs: defaultChoirs ?? this.defaultChoirs,
      defaultVoices: defaultVoices ?? this.defaultVoices,
      defaultClassNames: defaultClassNames ?? this.defaultClassNames,
      hasInitializedDefaults:
          hasInitializedDefaults ?? this.hasInitializedDefaults,
      hasUserOverrides: hasUserOverrides ?? this.hasUserOverrides,
    );
  }
}
