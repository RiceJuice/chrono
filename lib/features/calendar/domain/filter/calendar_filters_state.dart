enum CalendarVisibility { choir, meal, school }

class CalendarFiltersState {
  const CalendarFiltersState({
    this.choirs = const <String>[],
    this.voices = const <String>[],
    this.classNames = const <String>[],
    this.schoolTracks = const <String>[],
    this.diets = const <String>[],
    this.defaultChoirs = const <String>[],
    this.defaultVoices = const <String>[],
    this.defaultClassNames = const <String>[],
    this.defaultSchoolTracks = const <String>[],
    this.defaultDiets = const <String>[],
    this.hasInitializedDefaults = false,
    this.hasUserOverrides = false,
    this.isChoirExplicit = false,
    this.isVoiceExplicit = false,
    this.isClassNameExplicit = false,
    this.isSchoolTrackExplicit = false,
    this.isDietExplicit = false,
    this.showChoirCalendar = true,
    this.showMealCalendar = true,
    this.showSchoolCalendar = true,
  });

  final List<String> choirs;
  final List<String> voices;
  final List<String> classNames;
  final List<String> schoolTracks;
  final List<String> diets;
  final List<String> defaultChoirs;
  final List<String> defaultVoices;
  final List<String> defaultClassNames;
  final List<String> defaultSchoolTracks;
  final List<String> defaultDiets;
  final bool hasInitializedDefaults;
  final bool hasUserOverrides;
  final bool isChoirExplicit;
  final bool isVoiceExplicit;
  final bool isClassNameExplicit;
  final bool isSchoolTrackExplicit;
  final bool isDietExplicit;
  final bool showChoirCalendar;
  final bool showMealCalendar;
  final bool showSchoolCalendar;

  bool get hasActiveFilters =>
      choirs.isNotEmpty ||
      voices.isNotEmpty ||
      classNames.isNotEmpty ||
      schoolTracks.isNotEmpty ||
      diets.isNotEmpty;

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

  List<String> get dietDeviations => _visibleFilterChipsForCategory(
    selected: diets,
    defaults: defaultDiets,
    isExplicit: isDietExplicit,
  );

  bool get hasVisibleDeviationChips =>
      choirDeviations.isNotEmpty ||
      voiceDeviations.isNotEmpty ||
      classNameDeviations.isNotEmpty ||
      schoolTrackDeviations.isNotEmpty ||
      dietDeviations.isNotEmpty;

  bool isCalendarVisible(CalendarVisibility calendar) {
    return switch (calendar) {
      CalendarVisibility.choir => showChoirCalendar,
      CalendarVisibility.meal => showMealCalendar,
      CalendarVisibility.school => showSchoolCalendar,
    };
  }

  /// Unabhängige Kopie aller Listen (z. B. für Sheet-Entwurf / Wiederherstellen).
  CalendarFiltersState deepClone() {
    return CalendarFiltersState(
      choirs: List<String>.from(choirs),
      voices: List<String>.from(voices),
      classNames: List<String>.from(classNames),
      schoolTracks: List<String>.from(schoolTracks),
      diets: List<String>.from(diets),
      defaultChoirs: List<String>.from(defaultChoirs),
      defaultVoices: List<String>.from(defaultVoices),
      defaultClassNames: List<String>.from(defaultClassNames),
      defaultSchoolTracks: List<String>.from(defaultSchoolTracks),
      defaultDiets: List<String>.from(defaultDiets),
      hasInitializedDefaults: hasInitializedDefaults,
      hasUserOverrides: hasUserOverrides,
      isChoirExplicit: isChoirExplicit,
      isVoiceExplicit: isVoiceExplicit,
      isClassNameExplicit: isClassNameExplicit,
      isSchoolTrackExplicit: isSchoolTrackExplicit,
      isDietExplicit: isDietExplicit,
      showChoirCalendar: showChoirCalendar,
      showMealCalendar: showMealCalendar,
      showSchoolCalendar: showSchoolCalendar,
    );
  }

  CalendarFiltersState copyWith({
    List<String>? choirs,
    List<String>? voices,
    List<String>? classNames,
    List<String>? schoolTracks,
    List<String>? diets,
    List<String>? defaultChoirs,
    List<String>? defaultVoices,
    List<String>? defaultClassNames,
    List<String>? defaultSchoolTracks,
    List<String>? defaultDiets,
    bool? hasInitializedDefaults,
    bool? hasUserOverrides,
    bool? isChoirExplicit,
    bool? isVoiceExplicit,
    bool? isClassNameExplicit,
    bool? isSchoolTrackExplicit,
    bool? isDietExplicit,
    bool? showChoirCalendar,
    bool? showMealCalendar,
    bool? showSchoolCalendar,
  }) {
    return CalendarFiltersState(
      choirs: choirs ?? this.choirs,
      voices: voices ?? this.voices,
      classNames: classNames ?? this.classNames,
      schoolTracks: schoolTracks ?? this.schoolTracks,
      diets: diets ?? this.diets,
      defaultChoirs: defaultChoirs ?? this.defaultChoirs,
      defaultVoices: defaultVoices ?? this.defaultVoices,
      defaultClassNames: defaultClassNames ?? this.defaultClassNames,
      defaultSchoolTracks: defaultSchoolTracks ?? this.defaultSchoolTracks,
      defaultDiets: defaultDiets ?? this.defaultDiets,
      hasInitializedDefaults:
          hasInitializedDefaults ?? this.hasInitializedDefaults,
      hasUserOverrides: hasUserOverrides ?? this.hasUserOverrides,
      isChoirExplicit: isChoirExplicit ?? this.isChoirExplicit,
      isVoiceExplicit: isVoiceExplicit ?? this.isVoiceExplicit,
      isClassNameExplicit: isClassNameExplicit ?? this.isClassNameExplicit,
      isSchoolTrackExplicit:
          isSchoolTrackExplicit ?? this.isSchoolTrackExplicit,
      isDietExplicit: isDietExplicit ?? this.isDietExplicit,
      showChoirCalendar: showChoirCalendar ?? this.showChoirCalendar,
      showMealCalendar: showMealCalendar ?? this.showMealCalendar,
      showSchoolCalendar: showSchoolCalendar ?? this.showSchoolCalendar,
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
