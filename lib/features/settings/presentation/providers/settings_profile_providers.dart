import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_user_id_provider.dart';
import '../../../../core/database/database_provider.dart';
import '../../data/models/profile_snapshot.dart';
import '../../data/settings_profile_repository.dart';

final settingsProfileRepositoryProvider = Provider<SettingsProfileRepository>((
  ref,
) {
  return SettingsProfileRepository(ref.watch(dbProvider));
});

final syncedProfileProvider = StreamProvider<ProfileSnapshot?>((ref) {
  final userId = ref.watch(authUserIdProvider).value;
  if (userId == null) {
    return Stream<ProfileSnapshot?>.value(null);
  }

  final repository = ref.watch(settingsProfileRepositoryProvider);
  return repository.watchProfileByUserId(userId);
});
