import 'package:chronoapp/core/auth/auth_user_id_provider.dart';
import 'package:chronoapp/features/login/domain/guardian_active_child_picker.dart';
import 'package:chronoapp/features/login/domain/models/guardian_child_link.dart';
import 'package:chronoapp/features/login/presentation/providers/guardian_link_providers.dart';
import 'package:chronoapp/features/login/presentation/providers/profile_gate_provider.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_calendar_viewer.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_child_profile_display.dart';
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

GuardianChildLink _activeGuardianChildLink({
  required List<GuardianChildLink> confirmed,
  required String? activeChildId,
}) {
  if (activeChildId != null) {
    for (final link in confirmed) {
      if (link.childId == activeChildId) return link;
    }
  }
  return pickGuardianActiveChild(confirmed);
}

final effectiveCalendarProfileProvider =
    Provider<AsyncValue<ProfileSnapshot?>>((ref) {
  final ownAsync = ref.watch(syncedProfileProvider);
  final gate = ref.watch(profileGateDataProvider);

  return ownAsync.when(
    loading: () => ownAsync,
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
    data: (own) {
      if (!isGuardianCalendarViewer(gate: gate, ownProfile: own)) {
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

          final activeChildId = gate.activeChildId;
          final activeLink = _activeGuardianChildLink(
            confirmed: confirmed,
            activeChildId: activeChildId,
          );

          final profileAsync =
              ref.watch(linkedChildProfileProvider(activeLink.childId));
          return profileAsync.when(
            loading: () => const AsyncValue.loading(),
            error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
            data: (loaded) => AsyncValue.data(
              guardianChildProfileSnapshot(
                link: activeLink,
                loaded: loaded,
              ),
            ),
          );
        },
      );
    },
  );
});
