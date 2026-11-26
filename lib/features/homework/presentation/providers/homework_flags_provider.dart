import 'package:chronoapp/features/homework/presentation/providers/homework_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Personal flags are stored per profile on this device.
final homeworkFlagsProvider =
    AsyncNotifierProvider<HomeworkFlagsNotifier, Set<String>>(
      HomeworkFlagsNotifier.new,
    );

class HomeworkFlagsNotifier extends AsyncNotifier<Set<String>> {
  String? _key;

  @override
  Future<Set<String>> build() async {
    final profileId = ref.watch(effectiveHomeworkProfileIdProvider);
    _key = profileId == null ? null : 'homework_flags_$profileId';
    if (_key == null) return {};
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key!) ?? []).toSet();
  }

  Future<void> toggle(String taskId) async {
    final current = state.asData?.value ?? await future;
    final key = _key;
    if (key == null) return;
    final next = {...current};
    if (!next.remove(taskId)) next.add(taskId);
    state = AsyncData(next);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setStringList(key, next.toList())) {
        throw StateError('Markierung konnte nicht gespeichert werden.');
      }
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}
