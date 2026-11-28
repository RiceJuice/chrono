import 'models/guardian_child_link.dart';

String normalizeGuardianLinkStatus(String? raw) =>
    switch (raw?.trim().toLowerCase()) {
      'pending' => GuardianLinkStatus.pending,
      'confirmed' => GuardianLinkStatus.confirmed,
      'rejected' => GuardianLinkStatus.rejected,
      _ => GuardianLinkStatus.revoked,
    };

/// A complete server snapshot also removes deleted rows. Callers without a
/// successful server read must keep their cache instead of passing an empty list.
List<GuardianChildLink> mergeGuardianLinkCollections(
  Iterable<GuardianChildLink> local,
  Iterable<GuardianChildLink> remote,
) {
  final byId = {for (final link in local) link.id: link};
  return [
    for (final link in remote) mergeGuardianChildLinks(byId[link.id], link),
  ];
}

GuardianChildLink mergeGuardianChildLinks(
  GuardianChildLink? local,
  GuardianChildLink remote,
) {
  if (local != null && local.revision > remote.revision) return local;
  // Equal/unversioned snapshots prefer the server, including explicit false
  // permissions and null personal fields. Never revive revoked cached access.
  return remote;
}

bool guardianLinksHaveConfirmed(Iterable<GuardianChildLink> links) =>
    links.any((link) => link.isConfirmed);
