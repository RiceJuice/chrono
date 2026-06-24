import 'package:chronoapp/features/login/domain/guardian_link_status.dart';
import 'package:chronoapp/features/login/domain/models/guardian_child_link.dart';

List<GuardianChildLink> mergeGuardianOwnLinks({
  required List<GuardianChildLink> streamLinks,
  required List<GuardianChildLink> remoteLinks,
  required String guardianId,
}) {
  final ownStream = streamLinks
      .where((link) => link.guardianId == guardianId)
      .toList(growable: false);
  final ownRemote = remoteLinks
      .where((link) => link.guardianId == guardianId)
      .toList(growable: false);
  final merged = mergeGuardianLinkCollections(ownStream, ownRemote);
  merged.sort(
    (a, b) =>
        (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
  );
  return merged;
}
