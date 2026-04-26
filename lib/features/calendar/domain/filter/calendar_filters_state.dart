class CalendarFiltersState {
  const CalendarFiltersState({
    this.choirs = const <String>[],
    this.voices = const <String>[],
    this.classNames = const <String>[],
    this.schoolTracks = const <String>[],
    this.defaultChoirs = const <String>[],
    this.defaultVoices = const <String>[],
    this.defaultClassNames = const <String>[],
    this.defaultSchoolTracks = const <String>[],
    this.hasInitializedDefaults = false,
    this.hasUserOverrides = false,
    this.isChoirExplicit = false,
    this.isVoiceExplicit = false,
    this.isClassNameExplicit = false,
    this.isSchoolTrackExplicit = false,
  });

  final List<String> choirs;
  final List<String> voices;
  final List<String> classNames;
  final List<String> schoolTracks;
  final List<String> defaultChoirs;
  final List<String> defaultVoices;
  final List<String> defaultClassNames;
  final List<String> defaultSchoolTracks;
  final bool hasInitializedDefaults;
  final bool hasUserOverrides;
  final bool isChoirExplicit;
  final bool isVoiceExplicit;
  final bool isClassNameExplicit;
  final bool isSchoolTrackExplicit;

  bool get hasActiveFilters =>
      choirs.isNotEmpty ||
      voices.isNotEmpty ||
      classNames.isNotEmpty ||
      schoolTracks.isNotEmpty;

  List<String> get choirDeviations => _visibleFilterChipsForCategory(
        selected: choirs,
        defaults: defaultChoirs,
        isExplicit: isChoirExplicit,
      );

  List<String> get voiceDeviations => _visibleFilterChipsForCategory(
        selected: voices,
        defaults: defaultVoices,
        isExplicit: isVoiceExplicit,
      );

  List<String> get classNameDeviations => _visibleFilterChipsForCategory(
        selected: classNames,
        defaults: defaultClassNames,
        isExplicit: isClassNameExplicit,
      );

  List<String> get schoolTrackDeviations => _visibleFilterChipsForCategory(
        selected: schoolTracks,
        defaults: defaultSchoolTracks,
        isExplicit: isSchoolTrackExplicit,
      );

  bool get hasVisibleDeviationChips =>
      choirDeviations.isNotEmpty ||
      voiceDeviations.isNotEmpty ||
      classNameDeviations.isNotEmpty ||
      schoolTrackDeviations.isNotEmpty;

  CalendarFiltersState copyWith({
    List<String>? choirs,
    List<String>? voices,
    List<String>? classNames,
    List<String>? schoolTracks,
    List<String>? defaultChoirs,
    List<String>? defaultVoices,
    List<String>? defaultClassNames,
    List<String>? defaultSchoolTracks,
    bool? hasInitializedDefaults,
    bool? hasUserOverrides,
    bool? isChoirExplicit,
    bool? isVoiceExplicit,
    bool? isClassNameExplicit,
    bool? isSchoolTrackExplicit,
  }) {
    return CalendarFiltersState(
      choirs: choirs ?? this.choirs,
      voices: voices ?? this.voices,
      classNames: classNames ?? this.classNames,
      schoolTracks: schoolTracks ?? this.schoolTracks,
      defaultChoirs: defaultChoirs ?? this.defaultChoirs,
      defaultVoices: defaultVoices ?? this.defaultVoices,
      defaultClassNames: defaultClassNames ?? this.defaultClassNames,
      defaultSchoolTracks: defaultSchoolTracks ?? this.defaultSchoolTracks,
      hasInitializedDefaults:
          hasInitializedDefaults ?? this.hasInitializedDefaults,
      hasUserOverrides: hasUserOverrides ?? this.hasUserOverrides,
      isChoirExplicit: isChoirExplicit ?? this.isChoirExplicit,
      isVoiceExplicit: isVoiceExplicit ?? this.isVoiceExplicit,
      isClassNameExplicit: isClassNameExplicit ?? this.isClassNameExplicit,
      isSchoolTrackExplicit: isSchoolTrackExplicit ?? this.isSchoolTrackExplicit,
    );
  }
}

List<String> _selectedValuesNotInDefaults(
  List<String> selected,
  List<String> defaults,
) {
  if (selected.isEmpty) return const <String>[];
  final defaultSet = defaults.toSet();
  return selected.where((value) => !defaultSet.contains(value)).toList();
}

List<String> _visibleFilterChipsForCategory({
  required List<String> selected,
  required List<String> defaults,
  required bool isExplicit,
}) {
  if (isExplicit && selected.isNotEmpty) {
    return selected;
  }
  final deviations = _selectedValuesNotInDefaults(selected, defaults);
  if (deviations.isEmpty) return const <String>[];
  if (selected.length > 1) return selected;
  return deviations;
}
