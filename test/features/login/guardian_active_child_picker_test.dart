import 'package:chronoapp/features/login/domain/guardian_active_child_picker.dart';
import 'package:chronoapp/features/login/domain/models/guardian_child_link.dart';
import 'package:flutter_test/flutter_test.dart';

GuardianChildLink _link(String childId, String? className) {
  return GuardianChildLink(
    id: 'link-$childId',
    guardianId: 'guardian-1',
    childId: childId,
    status: GuardianLinkStatus.confirmed,
    childClassName: className,
  );
}

void main() {
  group('pickGuardianActiveChild', () {
    test('gibt einziges Kind zurück', () {
      final link = _link('child-1', '9b');
      expect(pickGuardianActiveChild([link]), link);
    });

    test('wählt höhere Klassenstufe', () {
      final lower = _link('child-9', '9b');
      final higher = _link('child-10', '10a');

      expect(
        pickGuardianActiveChild([lower, higher]).childId,
        'child-10',
      );
      expect(
        pickGuardianActiveChild([higher, lower]).childId,
        'child-10',
      );
    });

    test('vergleicht Buchstaben bei gleicher Stufe', () {
      final a = _link('child-a', '10a');
      final b = _link('child-b', '10b');

      expect(pickGuardianActiveChild([a, b]).childId, 'child-b');
    });

    test('bevorzugt Kind mit Klasse gegenüber fehlender Klasse', () {
      final withClass = _link('child-class', '8c');
      final withoutClass = _link('child-none', null);

      expect(
        pickGuardianActiveChild([withoutClass, withClass]).childId,
        'child-class',
      );
    });
  });
}
