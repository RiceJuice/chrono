import 'package:chronoapp/features/login/domain/models/guardian_child_link.dart';
import 'package:chronoapp/features/settings/presentation/widgets/guardian_child_switch_banners.dart';
import 'package:flutter_test/flutter_test.dart';

GuardianChildLink _link({
  required String id,
  required String childId,
  String status = GuardianLinkStatus.confirmed,
  String? childFirstName,
  String? childClassName,
}) {
  return GuardianChildLink(
    id: id,
    guardianId: 'guardian-1',
    childId: childId,
    status: status,
    childFirstName: childFirstName,
    childClassName: childClassName,
  );
}

void main() {
  group('inactiveConfirmedGuardianLinks', () {
    test('liefert keine Links ohne bestätigte Kinder', () {
      final links = [
        _link(id: '1', childId: 'child-1', status: GuardianLinkStatus.pending),
      ];

      expect(
        inactiveConfirmedGuardianLinks(
          links: links,
          guardianId: 'guardian-1',
          activeChildId: 'child-1',
        ),
        isEmpty,
      );
    });

    test('liefert leer wenn nur ein bestätigtes aktives Kind', () {
      final links = [
        _link(id: '1', childId: 'child-1'),
      ];

      expect(
        inactiveConfirmedGuardianLinks(
          links: links,
          guardianId: 'guardian-1',
          activeChildId: 'child-1',
        ),
        isEmpty,
      );
    });

    test('filtert aktives Kind bei mehreren bestätigten Kindern', () {
      final links = [
        _link(id: '1', childId: 'child-1', childFirstName: 'Anna'),
        _link(id: '2', childId: 'child-2', childFirstName: 'Ben'),
        _link(id: '3', childId: 'child-3', childFirstName: 'Cleo'),
      ];

      final inactive = inactiveConfirmedGuardianLinks(
        links: links,
        guardianId: 'guardian-1',
        activeChildId: 'child-2',
      );

      expect(inactive, hasLength(2));
      expect(inactive.map((link) => link.childId), ['child-1', 'child-3']);
    });

    test('ignoriert Links anderer Guardians', () {
      final links = [
        _link(id: '1', childId: 'child-1'),
        const GuardianChildLink(
          id: '2',
          guardianId: 'other-guardian',
          childId: 'child-2',
          status: GuardianLinkStatus.confirmed,
        ),
      ];

      final inactive = inactiveConfirmedGuardianLinks(
        links: links,
        guardianId: 'guardian-1',
        activeChildId: 'child-1',
      );

      expect(inactive, isEmpty);
    });
  });

  group('guardianChildSwitchBannersBlockHeight', () {
    test('liefert 0 ohne inaktive Kinder', () {
      expect(guardianChildSwitchBannersBlockHeight(0), 0);
    });

    test('berechnet Höhe für ein und mehrere Banner', () {
      expect(guardianChildSwitchBannersBlockHeight(1), 72);
      expect(guardianChildSwitchBannersBlockHeight(2), 144);
    });
  });

  group('guardianChildSwitchSubtitle', () {
    test('zeigt Klasse und Wechsel-Hinweis', () {
      final link = _link(
        id: '1',
        childId: 'child-1',
        childClassName: '7a',
      );

      expect(
        guardianChildSwitchSubtitle(link),
        'Klasse 7a · Kalender wechseln',
      );
    });

    test('zeigt nur Wechsel-Hinweis ohne Klasse', () {
      final link = _link(id: '1', childId: 'child-1');

      expect(guardianChildSwitchSubtitle(link), 'Kalender wechseln');
    });
  });
}
