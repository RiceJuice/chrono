import 'package:chronoapp/core/auth/auth_user_id_provider.dart';
import 'package:chronoapp/core/database/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/guardian_link_repository.dart';
import '../../domain/models/guardian_child_link.dart';

final guardianLinkRepositoryProvider = Provider<GuardianLinkRepository>((ref) {
  return GuardianLinkRepository(
    ref.watch(dbProvider),
    supabase: Supabase.instance.client,
  );
});

final guardianLinksProvider = StreamProvider<List<GuardianChildLink>>((ref) {
  final userId = ref.watch(authUserIdProvider).value;
  if (userId == null) {
    return Stream<List<GuardianChildLink>>.value(const []);
  }
  return ref.watch(guardianLinkRepositoryProvider).watchLinksForUser(userId);
});

final pendingGuardianLinksProvider =
    StreamProvider<List<GuardianChildLink>>((ref) {
  final userId = ref.watch(authUserIdProvider).value;
  if (userId == null) {
    return Stream<List<GuardianChildLink>>.value(const []);
  }
  return ref
      .watch(guardianLinkRepositoryProvider)
      .watchPendingForChild(userId);
});

final guardianLinkSummaryProvider = Provider<GuardianLinkSummary>((ref) {
  final userId = ref.watch(authUserIdProvider).value;
  if (userId == null) {
    return const GuardianLinkSummary(
      confirmedLinks: [],
      pendingLinks: [],
    );
  }
  final links = ref.watch(guardianLinksProvider).asData?.value ?? const [];
  final own = links
      .where((link) => link.guardianId == userId)
      .toList(growable: false);
  return GuardianLinkSummary(
    confirmedLinks:
        own.where((link) => link.isConfirmed).toList(growable: false),
    pendingLinks:
        own.where((link) => link.isPending).toList(growable: false),
  );
});
