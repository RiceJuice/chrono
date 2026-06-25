import 'package:chronoapp/features/login/domain/models/guardian_child_link.dart';
import 'package:chronoapp/features/login/presentation/services/guardian_link_bootstrap.dart';
import 'package:flutter_test/flutter_test.dart';

GuardianChildLink _link({
  required String id,
  required String childId,
  String status = GuardianLinkStatus.pending,
}) {
  return GuardianChildLink(
    id: id,
    guardianId: 'guardian-$id',
    childId: childId,
    status: status,
  );
}

void main() {
  group('mergePendingGuardianLinks', () {
    test('fügt neue Pending-Links hinzu', () {
      final existing = [_link(id: 'link-1', childId: 'child-a')];
      final incoming = [_link(id: 'link-2', childId: 'child-a')];

      final merged = mergePendingGuardianLinks(existing, incoming);

      expect(merged.map((link) => link.id), ['link-1', 'link-2']);
    });

    test('vermeidet Duplikate und aktualisiert bestehende Einträge', () {
      final existing = [
        _link(id: 'link-1', childId: 'child-a'),
      ];
      final incoming = [
        _link(
          id: 'link-1',
          childId: 'child-a',
          status: GuardianLinkStatus.pending,
        ),
        _link(id: 'link-2', childId: 'child-a'),
      ];

      final merged = mergePendingGuardianLinks(existing, incoming);

      expect(merged.map((link) => link.id), ['link-1', 'link-2']);
      expect(merged.length, 2);
    });

    test('entfernt nicht mehr pending Links aus der Queue', () {
      final existing = [
        _link(id: 'link-1', childId: 'child-a'),
        _link(id: 'link-2', childId: 'child-a'),
      ];
      final incoming = [
        _link(
          id: 'link-1',
          childId: 'child-a',
          status: GuardianLinkStatus.confirmed,
        ),
      ];

      final merged = mergePendingGuardianLinks(existing, incoming);

      expect(merged.map((link) => link.id), ['link-2']);
    });

    test('behält Remote-Einträge bei leerem Stream', () {
      final existing = [_link(id: 'link-remote', childId: 'child-a')];

      final merged = mergePendingGuardianLinks(existing, const []);

      expect(merged.map((link) => link.id), ['link-remote']);
    });
  });
}
