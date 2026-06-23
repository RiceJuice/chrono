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

final guardianLinkSummaryProvider =
    FutureProvider<GuardianLinkSummary>((ref) async {
  final userId = ref.watch(authUserIdProvider).value;
  if (userId == null) {
    return const GuardianLinkSummary(
      confirmedLinks: [],
      pendingLinks: [],
    );
  }
  ref.watch(guardianLinksProvider);
  return ref
      .read(guardianLinkRepositoryProvider)
      .loadSummaryForGuardian(userId);
});
