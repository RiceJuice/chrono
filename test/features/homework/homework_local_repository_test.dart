import 'package:chronoapp/features/homework/data/homework_local_repository.dart';
import 'package:chronoapp/features/homework/domain/models/homework_task.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeworkLocalRepository', () {
    late SharedPreferences prefs;
    late HomeworkLocalRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repository = HomeworkLocalRepository(prefs: prefs);
    });

    test('stores tasks per profile id', () async {
      final task = HomeworkTask(
        id: 'task-1',
        title: 'Lesen',
        isCompleted: false,
        createdAt: DateTime(2026, 6, 26, 9),
      );

      await repository.saveTasks('profile-a', [task]);
      await repository.saveTasks('profile-b', const []);

      final loadedA = await repository.loadTasks('profile-a');
      final loadedB = await repository.loadTasks('profile-b');

      expect(loadedA, hasLength(1));
      expect(loadedA.first.title, 'Lesen');
      expect(loadedB, isEmpty);
      expect(
        prefs.getString(HomeworkLocalRepository.storageKeyForProfile('profile-a')),
        isNotNull,
      );
    });
  });
}
