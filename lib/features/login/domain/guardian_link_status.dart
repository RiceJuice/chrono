import 'models/guardian_child_link.dart';
import 'models/guardian_child_share_permissions.dart';

int guardianLinkStatusRank(String? status) {
  switch (status?.trim().toLowerCase()) {
    case GuardianLinkStatus.confirmed:
      return 3;
    case GuardianLinkStatus.rejected:
    case GuardianLinkStatus.revoked:
      return 2;
    case GuardianLinkStatus.pending:
      return 1;
    default:
      return 0;
  }
}

String normalizeGuardianLinkStatus(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case GuardianLinkStatus.confirmed:
      return GuardianLinkStatus.confirmed;
    case GuardianLinkStatus.rejected:
      return GuardianLinkStatus.rejected;
    case GuardianLinkStatus.revoked:
      return GuardianLinkStatus.revoked;
    case GuardianLinkStatus.pending:
      return GuardianLinkStatus.pending;
    default:
      return GuardianLinkStatus.pending;
  }
}

String pickPreferredGuardianLinkStatus(String? a, String? b) {
  final normalizedA = normalizeGuardianLinkStatus(a);
  final normalizedB = normalizeGuardianLinkStatus(b);
  return guardianLinkStatusRank(normalizedA) >= guardianLinkStatusRank(normalizedB)
      ? normalizedA
      : normalizedB;
}

List<GuardianChildLink> mergeGuardianLinkCollections(
  Iterable<GuardianChildLink> local,
  Iterable<GuardianChildLink> remote,
) {
  final localById = {
    for (final link in local) link.id: link,
  };
  final mergedIds = <String>{};
  final merged = <GuardianChildLink>[];

  for (final remoteLink in remote) {
    mergedIds.add(remoteLink.id);
    merged.add(mergeGuardianChildLinks(localById[remoteLink.id], remoteLink));
  }
  for (final localLink in local) {
    if (!mergedIds.contains(localLink.id)) {
      merged.add(localLink);
    }
  }
  return merged;
}

GuardianChildLink mergeGuardianChildLinks(
  GuardianChildLink? local,
  GuardianChildLink remote,
) {
  if (local == null) {
    return remote.copyWithStatus(normalizeGuardianLinkStatus(remote.status));
  }

  final status = pickPreferredGuardianLinkStatus(local.status, remote.status);
  return GuardianChildLink(
    id: remote.id,
    guardianId: remote.guardianId,
    childId: remote.childId,
    status: status,
    createdAt: remote.createdAt ?? local.createdAt,
    respondedAt: remote.respondedAt ?? local.respondedAt,
    reminderSentAt: remote.reminderSentAt ?? local.reminderSentAt,
    childFirstName: local.childFirstName ?? remote.childFirstName,
    childLastName: local.childLastName ?? remote.childLastName,
    childClassName: local.childClassName ?? remote.childClassName,
    childChoir: local.childChoir ?? remote.childChoir,
    childVoice: local.childVoice ?? remote.childVoice,
    childSchoolTrack: local.childSchoolTrack ?? remote.childSchoolTrack,
    childDiet: local.childDiet ?? remote.childDiet,
    guardianFirstName: local.guardianFirstName ?? remote.guardianFirstName,
    guardianLastName: local.guardianLastName ?? remote.guardianLastName,
    sharePermissions: _mergeSharePermissions(
      local.sharePermissions,
      remote.sharePermissions,
    ),
  );
}

GuardianChildSharePermissions _mergeSharePermissions(
  GuardianChildSharePermissions local,
  GuardianChildSharePermissions remote,
) {
  if (remote.sharesAnything) return remote;
  if (local.sharesAnything) return local;
  return remote;
}

bool guardianLinksHaveConfirmed(Iterable<GuardianChildLink> links) {
  return links.any((link) => link.isConfirmed);
}
