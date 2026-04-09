import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/database/database_provider.dart';
import '../../data/models/profile_snapshot.dart';
import '../../data/settings_profile_repository.dart';

final settingsProfileRepositoryProvider = Provider<SettingsProfileRepository>((
  ref,
) {
  return SettingsProfileRepository(ref.watch(dbProvider));
});

final syncedProfileProvider = StreamProvider<ProfileSnapshot?>((ref) {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) {
    return Stream<ProfileSnapshot?>.value(null);
  }

  final repository = ref.watch(settingsProfileRepositoryProvider);
  return repository.watchProfileByUserId(userId);
});
