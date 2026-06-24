import 'package:chronoapp/features/calendar/domain/filter/calendar_filters_state.dart';
import 'package:chronoapp/features/login/domain/models/profile_gate_data.dart';
import 'package:chronoapp/features/settings/data/models/profile_snapshot.dart';
import 'package:chronoapp/features/settings/presentation/helpers/calendar_defaults_display.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveCalendarDefaultsDisplay', () {
    test('nutzt Kalender-Filter-Defaults wenn Profil leer ist', () {
      const filters = CalendarFiltersState(
        defaultChoirs: ['rädlinger'],
        defaultVoices: ['sopran'],
        defaultClassNames: ['8a'],
        defaultSchoolTracks: ['g8'],
        defaultDiets: ['normal'],
        hasInitializedDefaults: true,
      );

      final display = resolveCalendarDefaultsDisplay(
        profile: null,
        gate: const ProfileGateData(
          hasSession: true,
          emailConfirmed: true,
          firstName: 'Max',
          lastName: 'Test',
          className: null,
          schoolTrack: null,
          role: 'Schüler',
          voice: null,
          choir: null,
          onboardingCompletedAt: null,
          activeChildId: null,
          hasAnyGuardianLink: false,
          hasConfirmedGuardianLink: false,
          hasPendingGuardianLink: false,
        ),
        filters: filters,
      );

      expect(display.choir, 'Rädlinger');
      expect(display.voice, 'Sopran');
      expect(display.className, '8A');
      expect(display.schoolTrack, 'G8');
      expect(display.diet, 'Normal');
    });

    test('bevorzugt Profil vor Gate und Filtern', () {
      const filters = CalendarFiltersState(
        defaultChoirs: ['dkm'],
        hasInitializedDefaults: true,
      );

      final display = resolveCalendarDefaultsDisplay(
        profile: const ProfileSnapshot(
          firstName: 'Anna',
          lastName: 'Muster',
          className: '9b',
          schoolTrack: null,
          voice: 'Alt',
          role: 'Schüler',
          choir: 'Rädlinger',
          diet: null,
        ),
        gate: const ProfileGateData(
          hasSession: true,
          emailConfirmed: true,
          firstName: 'Anna',
          lastName: 'Muster',
          className: '8a',
          schoolTrack: null,
          role: 'Schüler',
          voice: 'Sopran',
          choir: 'DKM',
          onboardingCompletedAt: null,
          activeChildId: null,
          hasAnyGuardianLink: false,
          hasConfirmedGuardianLink: false,
          hasPendingGuardianLink: false,
        ),
        filters: filters,
      );

      expect(display.choir, 'Rädlinger');
      expect(display.voice, 'Alt');
      expect(display.className, '9b');
    });
  });
}
