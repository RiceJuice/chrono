import 'package:flutter_riverpod/flutter_riverpod.dart' as fr;

import '../../../../../../core/database/backend_enums.dart';
import '../../../../domain/models/calendar_entry.dart';
import 'calendar_filter_utils.dart';
import '../../calendar_providers.dart';

final calendarChoirFilterOptionsProvider = fr.Provider<List<String>>((ref) {
  return BackendChoir.values
      .where((value) => value != BackendChoir.unknown)
      .map((value) => normalizeFilterText(value.toBackend()))
      .whereType<String>()
      .toList(growable: false);
});

final calendarVoiceFilterOptionsProvider = fr.Provider<List<String>>((ref) {
  return BackendVoice.values
      .where((value) => value != BackendVoice.unknown)
      .map((value) => normalizeFilterText(value.toBackend()))
      .whereType<String>()
      .toList(growable: false);
});

final calendarClassFilterOptionsProvider =
    fr.Provider<fr.AsyncValue<List<String>>>((ref) {
      final entriesAsync = ref.watch(calendarAllEntriesProvider);
      return entriesAsync.whenData((entries) {
        final set = <String>{};
        for (final entry in entries) {
          _addClassName(set, entry);
        }
        final items = set.toList()..sort();
        return items;
      });
    });

void _addClassName(Set<String> set, CalendarEntry entry) {
  final className = normalizeFilterText(entry.className);
  if (className != null) {
    set.add(className);
  }
}
