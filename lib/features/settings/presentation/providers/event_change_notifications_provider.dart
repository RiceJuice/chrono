import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_user_id_provider.dart';
import '../../../calendar/presentation/providers/subjects_providers.dart';

final eventChangeNotificationsProvider = StreamProvider<bool>((ref) {
  final userId = ref.watch(authUserIdProvider).value;
  if (userId == null) {
    return Stream<bool>.value(true);
  }

  return ref
      .watch(profileCalendarPreferencesRepositoryProvider)
      .watchEventChangeNotifications(userId);
});

Future<void> setEventChangeNotifications(WidgetRef ref, bool enabled) async {
  final userId = ref.read(authUserIdProvider).value;
  if (userId == null) return;

  await ref
      .read(profileCalendarPreferencesRepositoryProvider)
      .setEventChangeNotifications(userId: userId, enabled: enabled);
}
