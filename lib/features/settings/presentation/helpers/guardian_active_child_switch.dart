import 'package:chronoapp/features/login/domain/models/guardian_child_link.dart';
import 'package:chronoapp/features/login/presentation/providers/auth_repository_provider.dart';
import 'package:chronoapp/features/login/presentation/providers/guardian_link_providers.dart';
import 'package:chronoapp/features/login/presentation/providers/profile_gate_provider.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_calendar_filter_sync_helper.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_child_profile_display.dart';
import 'package:chronoapp/features/settings/presentation/providers/effective_calendar_profile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> activateGuardianChildAndSyncFilters(
  WidgetRef ref, {
  required GuardianChildLink activeChild,
}) async {
  await ref
      .read(guardianLinkRepositoryProvider)
      .setActiveChild(activeChild.childId);
  await ref.read(authRepositoryProvider).updateProfile(
        activeChildId: activeChild.childId,
      );
  await ref.read(profileGateProvider).refresh();

  final loaded = await ref.read(
    linkedChildProfileProvider(activeChild.childId).future,
  );
  final profile = guardianChildProfileSnapshot(
    link: activeChild,
    loaded: loaded,
  );
  syncGuardianCalendarFilters(ref, profile);
}

Future<void> switchGuardianActiveChild(
  WidgetRef ref,
  GuardianChildLink link,
) async {
  await activateGuardianChildAndSyncFilters(ref, activeChild: link);
}
