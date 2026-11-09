import 'package:chronoapp/features/homework/presentation/providers/homework_flags_provider.dart';
import 'package:chronoapp/features/homework/presentation/providers/homework_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer container(String profile) => ProviderContainer(
    overrides: [effectiveHomeworkProfileIdProvider.overrideWithValue(profile)],
  );

  test(
    'flags survive provider recreation and remain scoped to a profile',
    () async {
      final first = container('first');
      await first.read(homeworkFlagsProvider.future);
      await first.read(homeworkFlagsProvider.notifier).toggle('task');
      first.dispose();
      final restored = container('first');
      final other = container('other');
      addTearDown(restored.dispose);
      addTearDown(other.dispose);
      expect(await restored.read(homeworkFlagsProvider.future), {'task'});
      expect(await other.read(homeworkFlagsProvider.future), isEmpty);
      await restored.read(homeworkFlagsProvider.notifier).toggle('task');
      expect(restored.read(homeworkFlagsProvider).requireValue, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('homework_flags_first'), isEmpty);
    },
  );
}
