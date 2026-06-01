import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/database/database_provider.dart';
import '../../data/profile_calendar_preferences_repository.dart';
import '../../data/subjects_repository.dart';
import '../../domain/models/calendar_subject.dart';

final subjectsRepositoryProvider = Provider<SubjectsRepository>((ref) {
  return SubjectsRepository(ref.watch(dbProvider));
});

final subjectsListProvider = StreamProvider<List<CalendarSubject>>((ref) {
  return ref.watch(subjectsRepositoryProvider).watchSubjects();
});

final profileCalendarPreferencesRepositoryProvider =
    Provider<ProfileCalendarPreferencesRepository>((ref) {
      return ProfileCalendarPreferencesRepository(ref.watch(dbProvider));
    });

final subjectAccentOverridesProvider =
    StreamProvider<Map<String, Color>>((ref) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        return Stream<Map<String, Color>>.value(const {});
      }
      return ref
          .watch(profileCalendarPreferencesRepositoryProvider)
          .watchSubjectAccentOverrides(userId);
    });
