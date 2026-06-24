import 'package:chronoapp/features/login/domain/models/guardian_child_link.dart';
import 'package:chronoapp/features/login/presentation/providers/auth_repository_provider.dart';
import 'package:chronoapp/features/login/presentation/providers/guardian_link_providers.dart';
import 'package:chronoapp/features/login/presentation/providers/profile_gate_provider.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_calendar_filter_sync_helper.dart';
import 'package:chronoapp/features/settings/presentation/providers/effective_calendar_profile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> switchGuardianActiveChild(
  WidgetRef ref,
  GuardianChildLink link,
) async {
  await ref.read(guardianLinkRepositoryProvider).setActiveChild(link.childId);
  await ref.read(authRepositoryProvider).updateProfile(
        activeChildId: link.childId,
      );
  await ref.read(profileGateProvider).refresh();

  final profile =
      await ref.read(linkedChildProfileProvider(link.childId).future);
  syncGuardianCalendarFilters(ref, profile);
}
