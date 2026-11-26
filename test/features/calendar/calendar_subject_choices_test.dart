import 'package:chronoapp/core/database/backend_enums.dart';
import 'package:chronoapp/core/database/arts_subject.dart';
import 'package:chronoapp/core/database/school_subject_choices.dart';
import 'package:chronoapp/core/database/school_subject_choices_cache.dart';
import 'package:chronoapp/features/calendar/domain/filter/calendar_filter_defaults.dart';
import 'package:chronoapp/features/calendar/domain/filter/calendar_display_filters.dart';
import 'package:chronoapp/features/calendar/domain/filter/calendar_filters_state.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/domain/layout/school_track_lane_order.dart';
import 'package:chronoapp/features/calendar/presentation/providers/filter/calendar/calendar_filters_provider.dart';
import 'package:chronoapp/features/calendar/presentation/providers/filter/search/search_filters_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

CalendarEntry lesson(
  String name, {
  String cohort = '11a',
  BackendSchoolTrack track = BackendSchoolTrack.ntg,
}) => CalendarEntry(
  id: '$name-$cohort-$track',
  eventName: name,
  className: cohort,
  schoolTrack: track,
  type: CalendarEntryType.lesson,
  accentColor: Colors.blue,
  startTime: DateTime(2026, 11, 16, 10),
  endTime: DateTime(2026, 11, 16, 11),
);

CalendarFiltersState filters({
  String? arts = 'Kunst',
  String? language = 'Latein',
  Map<String, dynamic> answers = const {},
}) => calendarFiltersStateFromProfileFields(
  choir: 'Rädlinger',
  voice: 'Tenor',
  className: '11a',
  schoolTrack: 'NTG',
  diet: 'Vegetarisch',
  artsSubject: arts,
  languageSubject: language,
  timetableChoices: answers,
);

List<String> visible(CalendarFiltersState state, List<CalendarEntry> entries) =>
    applyCalendarDisplayFilters(
      entries: entries,
      filters: state,
      hideUnknownWhenFilterActive: true,
      forEventList: true,
    ).map((e) => e.eventName).toList();

Map<String, dynamic> answer(
  String selected, {
  String cohort = '11a',
  String track = 'NTG',
  int year = 2026,
}) => {
  'selected': selected,
  'subjects': ['Latein', 'Französisch'],
  'class_name': cohort,
  'schooltrack': track,
  'school_year': year,
  'period_start': '$year-09-01T00:00:00',
  'period_end': '${year + 1}-09-01T00:00:00',
};

void main() {
  test('Supabase eligibility applies to grade 11 and NTG upper grades', () {
    expect(requiresLanguageSubject('11a'), true);
    expect(requiresLanguageSubject('Q12'), false);
    expect(requiresArtsSubject('11a', 'NTG'), true);
    expect(requiresArtsSubject('Q12', 'NTG'), true);
    expect(requiresArtsSubject('10a', 'NTG'), false);
    expect(requiresArtsSubject('11a', 'Musisch'), false);
  });

  test('only selected language and arts appear, general lessons remain', () {
    final entries = [
      lesson('Latein'),
      lesson('Französisch'),
      lesson('Kunst'),
      lesson('Musik', track: BackendSchoolTrack.musisch),
      lesson('Mathematik'),
    ];
    for (final language in languageSubjectOptions) {
      for (final arts in artsSubjectOptions) {
        expect(
          visible(filters(arts: arts, language: language), entries),
          containsAll([language, arts, 'Mathematik']),
        );
        expect(
          visible(filters(arts: arts, language: language), entries),
          hasLength(3),
        );
      }
    }
  });

  test('NTG music is also included in own Live Activity timetable', () {
    final music = lesson('Musik', track: BackendSchoolTrack.musisch);
    expect(
      lessonMatchesOwnSchoolProfile(
        entry: music,
        filters: filters(arts: 'Musik'),
      ),
      true,
    );
  });

  test('unanswered choices do not show both alternatives', () {
    expect(
      visible(filters(arts: null, language: null), [
        lesson('Latein'),
        lesson('Französisch'),
        lesson('Kunst'),
        lesson('Mathematik'),
      ]),
      ['Mathematik'],
    );
  });

  test('timetable answers apply only to their class, track and year', () {
    final cases = [
      answer('Französisch', cohort: '11b'),
      answer('Französisch', track: 'Musisch'),
      answer('Französisch', year: 2025),
    ];
    for (final value in cases) {
      expect(
        visible(filters(answers: {'q': value}), [
          lesson('Latein'),
          lesson('Französisch'),
        ]),
        ['Latein'],
      );
    }
    expect(
      visible(filters(language: null, answers: {'q': answer('Französisch')}), [
        lesson('Latein'),
        lesson('Französisch'),
      ]),
      ['Französisch'],
    );
  });

  test(
    'changing a choice updates generic answers, calendar and search together',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(calendarFiltersProvider.notifier)
          .replaceState(filters(answers: {'q': answer('Latein')}));
      container
          .read(calendarFiltersProvider.notifier)
          .applyProfileFilterChanges(languageSubject: 'Französisch');
      final state = container.read(calendarFiltersProvider);
      expect((state.timetableChoices['q'] as Map)['selected'], 'Französisch');
      container
          .read(searchFiltersProvider.notifier)
          .initializeFromCalendar(state);
      expect(
        visible(container.read(searchFiltersProvider), [
          lesson('Latein'),
          lesson('Französisch'),
        ]),
        ['Französisch'],
      );
      final clone = state.deepClone();
      expect(clone.languageSubject, 'Französisch');
      expect(clone.defaultChoirs, ['rädlinger']);
      expect(clone.defaultVoices, ['tenor']);
      expect(clone.defaultDiets, ['vegetarisch']);
    },
  );

  test(
    'cached server choices survive offline restart without leaking to another user or class',
    () async {
      SharedPreferences.setMockInitialValues({});
      final profile = <String, dynamic>{
        'class_name': '11a',
        'schooltrack': 'NTG',
        'arts_subject': 'Musik',
        'language_subject': 'Französisch',
        'timetable_subject_choices': {'q': answer('Französisch')},
      };
      await SchoolSubjectChoicesCache.save('alice', profile);
      final cached = await SchoolSubjectChoicesCache.supplement('alice', {
        'class_name': '11a',
        'schooltrack': 'NTG',
      });
      expect(cached['language_subject'], 'Französisch');
      expect(cached['arts_subject'], 'Musik');
      expect(
        (await SchoolSubjectChoicesCache.supplement('bob', {
          'class_name': '11a',
          'schooltrack': 'NTG',
        }))['arts_subject'],
        null,
      );
      expect(
        (await SchoolSubjectChoicesCache.supplement('alice', {
          'class_name': '12a',
          'schooltrack': 'NTG',
        }))['arts_subject'],
        null,
      );
    },
  );

  test('updating one answer leaves unrelated timetable answers unchanged', () {
    final other = answer('Latein', cohort: '11b');
    final next = updateSchoolSubjectChoices(
      existing: {'own': answer('Latein'), 'other': other},
      className: '11a',
      schoolTrack: 'NTG',
      languageSubject: 'Französisch',
    );
    expect((next['own'] as Map)['selected'], 'Französisch');
    expect(next['other'], other);
  });
}
