import 'package:chronoapp/features/login/domain/models/guardian_child_link.dart';
import 'package:chronoapp/features/settings/data/models/profile_snapshot.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_child_profile_display.dart';
import 'package:flutter_test/flutter_test.dart';

GuardianChildLink _link({
  String status = GuardianLinkStatus.confirmed,
  String? childFirstName,
  String? childLastName,
  String? childClassName,
}) {
  return GuardianChildLink(
    id: 'link-1',
    guardianId: 'guardian-1',
    childId: 'child-1',
    status: status,
    childFirstName: childFirstName,
    childLastName: childLastName,
    childClassName: childClassName,
  );
}

const _loadedProfile = ProfileSnapshot(
  firstName: 'Anna',
  lastName: 'Muster',
  className: '8a',
  schoolTrack: null,
  voice: null,
  role: 'Schüler',
  choir: null,
  diet: null,
);

void main() {
  group('guardianChildCardIsTappable', () {
    test('bestätigte Verknüpfung ist tippbar', () {
      expect(guardianChildCardIsTappable(_link()), isTrue);
    });

    test('ausstehende Verknüpfung ist nicht tippbar', () {
      expect(
        guardianChildCardIsTappable(
          _link(status: GuardianLinkStatus.pending),
        ),
        isFalse,
      );
    });
  });

  group('guardianChildCardSubtitle', () {
    test('zeigt Status für ausstehende Verknüpfung', () {
      expect(
        guardianChildCardSubtitle(
          link: _link(status: GuardianLinkStatus.pending),
          profile: null,
          isActive: false,
        ),
        'Bestätigung ausstehend',
      );
    });

    test('zeigt Aktiv-Hinweis für aktives Kind', () {
      expect(
        guardianChildCardSubtitle(
          link: _link(),
          profile: _loadedProfile,
          isActive: true,
        ),
        'Schüler · 8a · Aktiv',
      );
    });

    test('zeigt Profil-Hinweis für inaktives bestätigtes Kind', () {
      expect(
        guardianChildCardSubtitle(
          link: _link(),
          profile: _loadedProfile,
          isActive: false,
        ),
        'Schüler · 8a · Profil anzeigen',
      );
    });
  });

  group('guardianChildProfileSnapshot', () {
    test('nutzt geladenes Profil mit Link-Fallback', () {
      final snapshot = guardianChildProfileSnapshot(
        link: _link(childFirstName: 'Fallback'),
        loaded: _loadedProfile,
      );

      expect(snapshot.firstName, 'Anna');
      expect(snapshot.className, '8a');
    });

    test('fällt auf Link-Daten zurück', () {
      final snapshot = guardianChildProfileSnapshot(
        link: _link(
          childFirstName: 'Ben',
          childLastName: 'Test',
          childClassName: '9b',
        ),
        loaded: null,
      );

      expect(snapshot.firstName, 'Ben');
      expect(snapshot.lastName, 'Test');
      expect(snapshot.className, '9b');
    });
  });
}
