import 'package:chronoapp/core/startup/calendar_filter_startup_state.dart';
import 'package:chronoapp/features/login/domain/models/profile_gate_data.dart';
import 'package:chronoapp/features/settings/data/models/profile_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

ProfileGateData _guardianGate() {
  return const ProfileGateData(
    hasSession: true,
    emailConfirmed: true,
    hasConfirmedGuardianLink: true,
    hasAnyGuardianLink: true,
    hasPendingGuardianLink: false,
    activeChildId: 'child-1',
    role: 'Elternteil',
    firstName: 'Max',
    lastName: 'Muster',
    className: null,
    schoolTrack: null,
    voice: null,
    choir: null,
    diet: null,
    onboardingCompletedAt: null,
  );
}

void main() {
  tearDown(CalendarFilterStartupState.reset);

  group('CalendarFilterStartupState.preload', () {
    test('setzt Guardian-Filter aus Kindprofil', () {
      CalendarFilterStartupState.preload(
        gateData: _guardianGate(),
        childProfile: const ProfileSnapshot(
          firstName: 'Kind',
          lastName: 'Muster',
          choir: 'Giehl',
          voice: 'Bass',
          className: '10',
          schoolTrack: null,
          role: 'Schüler',
          diet: null,
        ),
      );

      final bootstrapped = CalendarFilterStartupState.consume();
      expect(bootstrapped, isNotNull);
      expect(bootstrapped!.choirs, ['giehl']);
      expect(bootstrapped.voices, ['bass']);
      expect(bootstrapped.classNames, ['10']);
    });

    test('setzt keine Guardian-Filter ohne Kindprofil', () {
      CalendarFilterStartupState.preload(gateData: _guardianGate());

      expect(CalendarFilterStartupState.consume()!.hasActiveFilters, isFalse);
    });

    test('Entzug des letzten Kindes verwirft alte Eltern-Profilfilter', () {
      CalendarFilterStartupState.preload(
        gateData: _guardianGate().copyWith(
          hasConfirmedGuardianLink: false,
          className: '10',
          choir: 'Giehl',
        ),
        diet: 'Vegetarisch',
      );
      final state = CalendarFilterStartupState.consume()!;
      expect(state.hasActiveFilters, isFalse);
      expect(state.classNames, isEmpty);
      expect(state.diets, isEmpty);
    });

    test('setzt Schüler-Filter aus Gate-Daten', () {
      CalendarFilterStartupState.preload(
        gateData: const ProfileGateData(
          hasSession: true,
          emailConfirmed: true,
          hasConfirmedGuardianLink: false,
          hasAnyGuardianLink: false,
          hasPendingGuardianLink: false,
          role: 'Schüler',
          firstName: 'Anna',
          lastName: 'Schul',
          className: '10',
          schoolTrack: 'Gymnasium',
          voice: 'Bass',
          choir: 'Giehl',
          diet: null,
          onboardingCompletedAt: null,
          activeChildId: null,
        ),
      );

      final bootstrapped = CalendarFilterStartupState.consume();
      expect(bootstrapped, isNotNull);
      expect(bootstrapped!.choirs, ['giehl']);
      expect(bootstrapped.voices, ['bass']);
      expect(bootstrapped.classNames, ['10']);
      expect(bootstrapped.schoolTracks, ['gymnasium']);
    });
  });
}
