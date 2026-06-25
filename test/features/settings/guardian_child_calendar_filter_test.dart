import 'package:chronoapp/features/calendar/domain/filter/calendar_filter_defaults.dart';
import 'package:chronoapp/features/login/domain/models/guardian_child_link.dart';
import 'package:chronoapp/features/settings/data/models/profile_snapshot.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_child_profile_display.dart';
import 'package:flutter_test/flutter_test.dart';

GuardianChildLink _link({
  String? childClassName,
  String? childChoir,
  String? childVoice,
  String? childSchoolTrack,
  String? childDiet,
}) {
  return GuardianChildLink(
    id: 'link-1',
    guardianId: 'guardian-1',
    childId: 'child-1',
    status: GuardianLinkStatus.confirmed,
    childClassName: childClassName,
    childChoir: childChoir,
    childVoice: childVoice,
    childSchoolTrack: childSchoolTrack,
    childDiet: childDiet,
  );
}

void main() {
  group('guardianChildProfileSnapshot', () {
    test('nutzt Link-Felder als Fallback ohne geladenes Profil', () {
      final profile = guardianChildProfileSnapshot(
        link: _link(
          childClassName: '10',
          childChoir: 'Giehl',
          childVoice: 'Bass',
          childSchoolTrack: 'Gymnasium',
          childDiet: 'Normal',
        ),
        loaded: null,
      );

      expect(profile.className, '10');
      expect(profile.choir, 'Giehl');
      expect(profile.voice, 'Bass');
      expect(profile.schoolTrack, 'Gymnasium');
      expect(profile.diet, 'Normal');
    });

    test('bevorzugt geladenes Profil gegenüber Link-Fallback', () {
      final profile = guardianChildProfileSnapshot(
        link: _link(childChoir: 'Giehl', childVoice: 'Tenor'),
        loaded: const ProfileSnapshot(
          firstName: null,
          lastName: null,
          className: null,
          schoolTrack: null,
          voice: 'Bass',
          role: null,
          choir: 'DKM',
          diet: null,
        ),
      );

      expect(profile.choir, 'DKM');
      expect(profile.voice, 'Bass');
    });
  });

  group('Kalenderfilter aus Kind-Link', () {
    test('setzt Chor, Stimme und Klasse aus Link-Snapshot', () {
      final profile = guardianChildProfileSnapshot(
        link: _link(
          childClassName: '10',
          childChoir: 'Giehl',
          childVoice: 'Bass',
        ),
        loaded: null,
      );
      final filters = calendarFiltersStateFromProfileFields(
        choir: profile.choir,
        voice: profile.voice,
        className: profile.className,
        schoolTrack: profile.schoolTrack,
        diet: profile.diet,
      );

      expect(filters.choirs, ['giehl']);
      expect(filters.voices, ['bass']);
      expect(filters.classNames, ['10']);
      expect(filters.hasInitializedDefaults, isTrue);
      expect(filters.hasActiveFilters, isTrue);
    });
  });
}
