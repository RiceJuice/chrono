import 'package:chronoapp/core/auth/auth_user_id_provider.dart';
import 'package:chronoapp/features/login/domain/guardian_active_child_picker.dart';
import 'package:chronoapp/features/login/domain/models/guardian_child_link.dart';
import 'package:chronoapp/features/login/domain/models/profile_gate_data.dart';
import 'package:chronoapp/features/login/presentation/providers/guardian_link_providers.dart';
import 'package:chronoapp/features/login/presentation/providers/profile_gate_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String? resolveActiveGuardianChildId({
  required ProfileGateData gate,
  required List<GuardianChildLink> confirmed,
}) {
  if (confirmed.isEmpty) return null;

  final activeChildId = gate.activeChildId;
  if (activeChildId != null) {
    for (final link in confirmed) {
      if (link.childId == activeChildId) return activeChildId;
    }
  }

  return pickGuardianActiveChild(confirmed).childId;
}

final activeGuardianChildIdProvider = Provider<String?>((ref) {
  final gate = ref.watch(profileGateDataProvider);
  final userId = ref.watch(authUserIdProvider).value;
  if (userId == null) return null;

  final links = ref.watch(guardianLinksProvider).asData?.value;
  if (links == null) return null;

  final confirmed = links
      .where((link) => link.isConfirmed && link.guardianId == userId)
      .toList(growable: false);
  return resolveActiveGuardianChildId(gate: gate, confirmed: confirmed);
});
