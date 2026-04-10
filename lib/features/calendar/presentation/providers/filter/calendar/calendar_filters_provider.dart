import 'package:flutter_riverpod/flutter_riverpod.dart' as fr;

import '../../../../../settings/data/models/profile_snapshot.dart';
import 'calendar_filter_utils.dart';
import 'calendar_filters_state.dart';

class CalendarFiltersNotifier extends fr.Notifier<CalendarFiltersState> {
  @override
  CalendarFiltersState build() => const CalendarFiltersState();

  void initializeFromProfile(ProfileSnapshot? profile) {
    final defaultChoirs = normalizedFilterList([profile?.choir]);
    final defaultVoices = const <String>[];
    final defaultClassNames = normalizedFilterList([profile?.className]);

    if (!state.hasInitializedDefaults || !state.hasUserOverrides) {
      state = state.copyWith(
        choirs: defaultChoirs,
        voices: defaultVoices,
        classNames: defaultClassNames,
        defaultChoirs: defaultChoirs,
        defaultVoices: defaultVoices,
        defaultClassNames: defaultClassNames,
        hasInitializedDefaults: true,
        hasUserOverrides: false,
      );
      return;
    }

    state = state.copyWith(
      choirs: state.choirs,
      voices: state.voices,
      classNames: state.classNames,
      defaultChoirs: defaultChoirs,
      defaultVoices: defaultVoices,
      defaultClassNames: defaultClassNames,
      hasInitializedDefaults: true,
    );
  }

  void toggleChoir(String value) {
    state = state.copyWith(
      choirs: _toggleInList(state.choirs, value),
      hasUserOverrides: true,
    );
  }

  void toggleVoice(String value) {
    state = state.copyWith(
      voices: _toggleInList(state.voices, value),
      hasUserOverrides: true,
    );
  }

  void toggleClassName(String value) {
    state = state.copyWith(
      classNames: _toggleInList(state.classNames, value),
      hasUserOverrides: true,
    );
  }

  void clearChoirs() {
    state = state.copyWith(choirs: const <String>[], hasUserOverrides: true);
  }

  void clearVoices() {
    state = state.copyWith(voices: const <String>[], hasUserOverrides: true);
  }

  void clearClassNames() {
    state = state.copyWith(classNames: const <String>[], hasUserOverrides: true);
  }

  void removeChoir(String value) {
    state = state.copyWith(
      choirs: _removeFromList(state.choirs, value),
      hasUserOverrides: true,
    );
  }

  void removeVoice(String value) {
    state = state.copyWith(
      voices: _removeFromList(state.voices, value),
      hasUserOverrides: true,
    );
  }

  void removeClassName(String value) {
    state = state.copyWith(
      classNames: _removeFromList(state.classNames, value),
      hasUserOverrides: true,
    );
  }

  void resetToDefaults() {
    state = state.copyWith(
      choirs: state.defaultChoirs,
      voices: state.defaultVoices,
      classNames: state.defaultClassNames,
      hasUserOverrides: false,
    );
  }
}

List<String> _toggleInList(List<String> values, String value) {
  final normalized = normalizeFilterText(value);
  if (normalized == null) return values;

  final set = values.toSet();
  if (set.contains(normalized)) {
    set.remove(normalized);
  } else {
    set.add(normalized);
  }
  final items = set.toList()..sort();
  return items;
}

List<String> _removeFromList(List<String> values, String value) {
  final normalized = normalizeFilterText(value);
  if (normalized == null) return values;
  final items = values.where((item) => item != normalized).toList()..sort();
  return items;
}

final calendarFiltersProvider =
    fr.NotifierProvider<CalendarFiltersNotifier, CalendarFiltersState>(
      CalendarFiltersNotifier.new,
    );
