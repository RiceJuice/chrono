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
    this.isChoirExplicit = false,
    this.isVoiceExplicit = false,
    this.isClassNameExplicit = false,
  });

  final List<String> choirs;
  final List<String> voices;
  final List<String> classNames;
  final List<String> defaultChoirs;
  final List<String> defaultVoices;
  final List<String> defaultClassNames;
  final bool hasInitializedDefaults;
  final bool hasUserOverrides;
  final bool isChoirExplicit;
  final bool isVoiceExplicit;
  final bool isClassNameExplicit;

  bool get hasActiveFilters =>
      choirs.isNotEmpty || voices.isNotEmpty || classNames.isNotEmpty;

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

  bool get hasVisibleDeviationChips =>
      choirDeviations.isNotEmpty ||
      voiceDeviations.isNotEmpty ||
      classNameDeviations.isNotEmpty;

  CalendarFiltersState copyWith({
    List<String>? choirs,
    List<String>? voices,
    List<String>? classNames,
    List<String>? defaultChoirs,
    List<String>? defaultVoices,
    List<String>? defaultClassNames,
    bool? hasInitializedDefaults,
    bool? hasUserOverrides,
    bool? isChoirExplicit,
    bool? isVoiceExplicit,
    bool? isClassNameExplicit,
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
      isChoirExplicit: isChoirExplicit ?? this.isChoirExplicit,
      isVoiceExplicit: isVoiceExplicit ?? this.isVoiceExplicit,
      isClassNameExplicit: isClassNameExplicit ?? this.isClassNameExplicit,
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
