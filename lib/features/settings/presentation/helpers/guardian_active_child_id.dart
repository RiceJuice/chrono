import 'package:chronoapp/core/auth/auth_user_id_provider.dart';
import 'package:chronoapp/features/login/domain/guardian_active_child_picker.dart';
import 'package:chronoapp/features/login/domain/models/guardian_child_link.dart';
import 'package:chronoapp/features/login/domain/models/profile_gate_data.dart';
import 'package:chronoapp/features/login/presentation/providers/guardian_link_providers.dart';
import 'package:chronoapp/features/login/presentation/providers/profile_gate_provider.dart';
import 'package:chronoapp/features/settings/data/settings_profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

List<GuardianChildLink> confirmedGuardianOwnLinks({
  required List<GuardianChildLink> links,
  required String guardianId,
}) {
  return links
      .where((link) => link.isConfirmed && link.guardianId == guardianId)
      .toList(growable: false);
}

GuardianChildLink resolveActiveGuardianChildLink({
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

String? resolveActiveGuardianChildId({
  required ProfileGateData gate,
  required List<GuardianChildLink> confirmed,
}) {
  if (confirmed.isEmpty) return null;
  return resolveActiveGuardianChildLink(
    confirmed: confirmed,
    activeChildId: gate.activeChildId,
  ).childId;
}

String? _resolveFromGateOrConfirmed({
  required ProfileGateData gate,
  required List<GuardianChildLink> confirmed,
}) {
  final fromLinks = resolveActiveGuardianChildId(gate: gate, confirmed: confirmed);
  if (fromLinks != null && fromLinks.isNotEmpty) return fromLinks;

  final fromGate = gate.activeChildId?.trim();
  if (fromGate != null && fromGate.isNotEmpty) return fromGate;

  return null;
}

final activeGuardianChildIdProvider = Provider<String?>((ref) {
  final gate = ref.watch(profileGateDataProvider);
  final userId = ref.watch(authUserIdProvider).value;
  if (userId == null) return null;

  final linksAsync = ref.watch(guardianLinksProvider);
  return linksAsync.maybeWhen(
    data: (links) => _resolveFromGateOrConfirmed(
      gate: gate,
      confirmed: confirmedGuardianOwnLinks(links: links, guardianId: userId),
    ),
    orElse: () {
      final fromGate = gate.activeChildId?.trim();
      if (fromGate != null && fromGate.isNotEmpty) return fromGate;
      return null;
    },
  );
});

/// Kind-ID für Kalender-Updates — wartet ggf. auf Links und nutzt Remote-Fallback.
Future<String> requireActiveGuardianChildId(WidgetRef ref) async {
  final gate = ref.read(profileGateDataProvider);
  final userId = ref.read(authUserIdProvider).value;
  if (userId == null) {
    throw SettingsProfileRepositoryException('Nicht angemeldet.');
  }

  String? resolveFromLinks(List<GuardianChildLink> links) {
    return _resolveFromGateOrConfirmed(
      gate: gate,
      confirmed: confirmedGuardianOwnLinks(links: links, guardianId: userId),
    );
  }

  final fromStream = resolveFromLinks(await ref.read(guardianLinksProvider.future));
  if (fromStream != null) return fromStream;

  if (gate.hasConfirmedGuardianLink) {
    final summary = await ref
        .read(guardianLinkRepositoryProvider)
        .loadSummaryForGuardian(userId);
    final fromSummary = resolveFromLinks(summary.confirmedLinks);
    if (fromSummary != null) return fromSummary;
  }

  throw SettingsProfileRepositoryException(
    'Kein aktives Kind ausgewählt. Bitte in der Familie ein Kind für den Kalender aktivieren.',
  );
}
