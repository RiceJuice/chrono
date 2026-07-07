import 'package:chronoapp/features/login/domain/models/guardian_child_link.dart';
import 'package:chronoapp/features/login/domain/models/profile_gate_data.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_active_child_id.dart';
import 'package:flutter_test/flutter_test.dart';

const _gate = ProfileGateData(
  hasSession: true,
  emailConfirmed: true,
  firstName: 'Erika',
  lastName: 'Muster',
  className: null,
  schoolTrack: null,
  role: 'Elternteil',
  voice: null,
  choir: null,
  diet: null,
  onboardingCompletedAt: null,
  activeChildId: 'child-b',
  hasAnyGuardianLink: true,
  hasConfirmedGuardianLink: true,
  hasPendingGuardianLink: false,
);

const _linkA = GuardianChildLink(
  id: 'link-a',
  guardianId: 'guardian-1',
  childId: 'child-a',
  status: 'confirmed',
  childClassName: '8a',
);

const _linkB = GuardianChildLink(
  id: 'link-b',
  guardianId: 'guardian-1',
  childId: 'child-b',
  status: 'confirmed',
  childClassName: '10a',
);

void main() {
  group('resolveActiveGuardianChildId', () {
    test('nutzt activeChildId aus dem Gate wenn bestätigt', () {
      expect(
        resolveActiveGuardianChildId(
          gate: _gate,
          confirmed: const [_linkA, _linkB],
        ),
        'child-b',
      );
    });

    test('fällt auf höchste Klasse zurück wenn activeChildId fehlt', () {
      expect(
        resolveActiveGuardianChildId(
          gate: _gate.copyWith(activeChildId: null),
          confirmed: const [_linkA, _linkB],
        ),
        'child-b',
      );
    });

    test('liefert null wenn keine bestätigten Links vorhanden sind', () {
      expect(
        resolveActiveGuardianChildId(
          gate: _gate,
          confirmed: const [],
        ),
        isNull,
      );
    });
  });
}
