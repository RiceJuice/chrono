import 'dart:convert';
import 'dart:math';

import 'package:chronoapp/features/homework/domain/models/homework_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeworkLocalRepository {
  HomeworkLocalRepository({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  final _random = Random();

  static String storageKeyForProfile(String profileId) =>
      'homework_tasks_$profileId';

  Future<SharedPreferences> _preferences() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<List<HomeworkTask>> loadTasks(String profileId) async {
    if (profileId.isEmpty) return const [];

    final prefs = await _preferences();
    final raw = prefs.getString(storageKeyForProfile(profileId));
    if (raw == null || raw.isEmpty) return const [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map>()
        .map((entry) => HomeworkTask.fromJson(Map<String, dynamic>.from(entry)))
        .toList(growable: false);
  }

  Future<void> saveTasks(String profileId, List<HomeworkTask> tasks) async {
    if (profileId.isEmpty) return;

    final prefs = await _preferences();
    final encoded = jsonEncode(tasks.map((task) => task.toJson()).toList());
    await prefs.setString(storageKeyForProfile(profileId), encoded);
  }

  Future<void> clearTasks(String profileId) async {
    if (profileId.isEmpty) return;
    final prefs = await _preferences();
    await prefs.remove(storageKeyForProfile(profileId));
  }

  String createTaskId() {
    return '${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(1 << 32)}';
  }
}
