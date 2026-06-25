import 'package:chronoapp/features/login/data/guardian_link_repository.dart';
import 'package:chronoapp/features/login/domain/models/guardian_child_link.dart';
import 'package:flutter_test/flutter_test.dart';

GuardianChildLink _link({
  required String id,
  required String childId,
  required String guardianId,
  String status = GuardianLinkStatus.pending,
}) {
  return GuardianChildLink(
    id: id,
    guardianId: guardianId,
    childId: childId,
    status: status,
  );
}

void main() {
  group('GuardianLinkRepository.pendingLinksForChild', () {
    test('filtert pending Links für das Kind', () {
      const childId = 'child-a';
      final links = [
        _link(
          id: 'link-1',
          childId: childId,
          guardianId: 'guardian-1',
        ),
        _link(
          id: 'link-2',
          childId: 'child-b',
          guardianId: 'guardian-2',
        ),
        _link(
          id: 'link-3',
          childId: childId,
          guardianId: 'guardian-3',
          status: GuardianLinkStatus.confirmed,
        ),
      ];

      final pending =
          GuardianLinkRepository.pendingLinksForChild(links, childId);

      expect(pending.map((link) => link.id), ['link-1']);
    });

    test('liefert leere Liste ohne passende Pending-Links', () {
      final links = [
        _link(
          id: 'link-1',
          childId: 'child-b',
          guardianId: 'guardian-1',
        ),
      ];

      final pending =
          GuardianLinkRepository.pendingLinksForChild(links, 'child-a');

      expect(pending, isEmpty);
    });
  });
}
