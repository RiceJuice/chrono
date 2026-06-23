import 'package:chronoapp/core/auth/auth_user_id_provider.dart';
import 'package:chronoapp/features/login/domain/models/login_flow_role_ids.dart';
import 'package:chronoapp/features/login/presentation/providers/guardian_link_providers.dart';
import 'package:chronoapp/features/login/presentation/providers/profile_gate_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/profile_snapshot.dart';
import 'settings_profile_providers.dart';

final linkedChildProfileProvider =
    StreamProvider.family<ProfileSnapshot?, String>((ref, childId) {
  if (childId.isEmpty) {
    return Stream<ProfileSnapshot?>.value(null);
  }
  return ref
      .watch(settingsProfileRepositoryProvider)
      .watchProfileByUserId(childId);
});

final effectiveCalendarProfileProvider =
    Provider<AsyncValue<ProfileSnapshot?>>((ref) {
  final ownAsync = ref.watch(syncedProfileProvider);
  return ownAsync.when(
    loading: () => ownAsync,
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
    data: (own) {
      if (own?.role?.trim() != LoginFlowRoleIds.guardian) {
        return AsyncValue.data(own);
      }

      final userId = ref.watch(authUserIdProvider).value;
      if (userId == null) return const AsyncValue.data(null);

      final linksAsync = ref.watch(guardianLinksProvider);
      return linksAsync.when(
        loading: () => const AsyncValue.loading(),
        error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
        data: (links) {
          final confirmed = links
              .where((link) => link.isConfirmed && link.guardianId == userId)
              .toList(growable: false);
          if (confirmed.isEmpty) return const AsyncValue.data(null);

          final activeChildId =
              ref.read(profileGateProvider).data.activeChildId;
          final childId = activeChildId != null &&
                  confirmed.any((link) => link.childId == activeChildId)
              ? activeChildId
              : confirmed.first.childId;

          return ref.watch(linkedChildProfileProvider(childId));
        },
      );
    },
  );
});
