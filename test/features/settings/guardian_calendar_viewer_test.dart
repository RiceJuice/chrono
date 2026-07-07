import 'package:chronoapp/core/auth/profile_role_ids.dart';
import 'package:chronoapp/features/login/domain/models/login_flow_role_ids.dart';
import 'package:chronoapp/features/login/domain/models/profile_gate_data.dart';
import 'package:chronoapp/features/settings/data/models/profile_snapshot.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_calendar_viewer.dart';
import 'package:flutter_test/flutter_test.dart';

const _gateWithConfirmedLink = ProfileGateData(
  hasSession: true,
  emailConfirmed: true,
  firstName: 'Erika',
  lastName: 'Muster',
  className: null,
  schoolTrack: null,
  role: LoginFlowRoleIds.guardian,
  voice: null,
  choir: null,
  diet: null,
  onboardingCompletedAt: null,
  activeChildId: 'child-1',
  hasAnyGuardianLink: true,
  hasConfirmedGuardianLink: true,
  hasPendingGuardianLink: false,
);

void main() {
  group('isGuardianCalendarViewer', () {
    test('erkennt Elternteil mit bestätigter Verknüpfung', () {
      expect(
        isGuardianCalendarViewer(gate: _gateWithConfirmedLink),
        isTrue,
      );
    });

    test('erkennt Admin-Elternteil mit bestätigter Verknüpfung', () {
      expect(
        isGuardianCalendarViewer(
          gate: _gateWithConfirmedLink.copyWith(
            role: ProfileRoleIds.admin,
          ),
        ),
        isTrue,
      );
    });

    test('ignoriert Schüler ohne Verknüpfung', () {
      expect(
        isGuardianCalendarViewer(
          gate: const ProfileGateData(
            hasSession: true,
            emailConfirmed: true,
            firstName: 'Anna',
            lastName: 'Schul',
            className: '8a',
            schoolTrack: 'Gymnasium',
            role: LoginFlowRoleIds.student,
            voice: 'Sopran',
            choir: 'Rädlinger',
            onboardingCompletedAt: null,
            activeChildId: null,
            hasAnyGuardianLink: false,
            hasConfirmedGuardianLink: false,
            hasPendingGuardianLink: false,
          ),
        ),
        isFalse,
      );
    });

    test('ignoriert Elternteil ohne bestätigte Verknüpfung', () {
      expect(
        isGuardianCalendarViewer(
          gate: _gateWithConfirmedLink.copyWith(
            role: LoginFlowRoleIds.guardian,
            hasConfirmedGuardianLink: false,
          ),
          ownProfile: const ProfileSnapshot(
            firstName: 'Erika',
            lastName: 'Muster',
            className: null,
            schoolTrack: null,
            voice: null,
            role: LoginFlowRoleIds.guardian,
            choir: null,
            diet: null,
          ),
        ),
        isFalse,
      );
    });
  });
}
