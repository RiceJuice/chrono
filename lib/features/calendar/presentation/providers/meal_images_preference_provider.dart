import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_user_id_provider.dart';
import 'subjects_providers.dart';

final showMealImagesProvider = StreamProvider<bool>((ref) {
  final userId = ref.watch(authUserIdProvider).value;
  if (userId == null) {
    return Stream<bool>.value(true);
  }

  return ref
      .watch(profileCalendarPreferencesRepositoryProvider)
      .watchShowMealImages(userId);
});

Future<void> setShowMealImages(WidgetRef ref, bool enabled) async {
  final userId = ref.read(authUserIdProvider).value;
  if (userId == null) return;

  await ref
      .read(profileCalendarPreferencesRepositoryProvider)
      .setShowMealImages(userId: userId, enabled: enabled);
}
