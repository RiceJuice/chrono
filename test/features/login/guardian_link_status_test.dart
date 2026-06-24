import 'package:chronoapp/features/login/domain/guardian_link_status.dart';
import 'package:chronoapp/features/login/domain/models/guardian_child_link.dart';
import 'package:flutter_test/flutter_test.dart';

GuardianChildLink _link(String status) {
  return GuardianChildLink(
    id: 'link-1',
    guardianId: 'guardian-1',
    childId: 'child-1',
    status: status,
    childFirstName: 'Max',
    childLastName: 'Muster',
  );
}

void main() {
  group('mergeGuardianChildLinks', () {
    test('bevorzugt bestätigt gegenüber ausstehend (lokal)', () {
      final merged = mergeGuardianChildLinks(
        _link(GuardianLinkStatus.confirmed),
        _link(GuardianLinkStatus.pending),
      );
      expect(merged.isConfirmed, isTrue);
    });

    test('bevorzugt bestätigt gegenüber ausstehend (remote)', () {
      final merged = mergeGuardianChildLinks(
        _link(GuardianLinkStatus.pending),
        _link(GuardianLinkStatus.confirmed),
      );
      expect(merged.isConfirmed, isTrue);
    });
  });

  group('mergeGuardianLinkCollections', () {
    test('übernimmt bestätigten Remote-Status trotz ausstehend lokal', () {
      final local = [
        _link(GuardianLinkStatus.pending),
      ];
      final remote = [
        _link(GuardianLinkStatus.confirmed),
      ];

      final merged = mergeGuardianLinkCollections(local, remote);

      expect(merged, hasLength(1));
      expect(merged.single.isConfirmed, isTrue);
    });

    test('behält lokale Links ohne Remote-Eintrag', () {
      final localOnly = GuardianChildLink(
        id: 'link-local',
        guardianId: 'guardian-1',
        childId: 'child-local',
        status: GuardianLinkStatus.pending,
      );
      final remote = [
        _link(GuardianLinkStatus.confirmed),
      ];

      final merged = mergeGuardianLinkCollections([localOnly], remote);

      expect(merged, hasLength(2));
      expect(
        merged.where((link) => link.id == 'link-local').single.isPending,
        isTrue,
      );
    });
  });
}
