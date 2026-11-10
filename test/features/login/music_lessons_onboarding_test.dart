import 'package:chronoapp/features/login/domain/models/profile_gate_data.dart';
import 'package:chronoapp/features/login/presentation/routes/login_flow_specs.dart';
import 'package:chronoapp/features/login/presentation/routes/login_paths.dart';
import 'package:chronoapp/features/music_lessons/domain/music_lesson_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final student = const ProfileGateData.signedOut().copyWith(
    hasSession: true,
    emailConfirmed: true,
    role: 'Schüler',
    firstName: 'Max',
    lastName: 'Beispiel',
    className: '8a',
    schoolTrack: 'Musisch',
    diet: 'Standard',
  );

  test('music lessons come after personal data and can be skipped', () {
    expect(
      resolveRequiredOnboardingPath(student.copyWith(className: '')),
      LoginPaths.personalData,
    );
    expect(resolveRequiredOnboardingPath(student), LoginPaths.musicLessons);
    expect(
      resolveRequiredOnboardingPath(
        student.copyWith(
          musicLessons: MusicLessonSchedule(
            startsOn: DateTime.utc(2026, 11, 10),
          ),
        ),
      ),
      LoginPaths.choir,
    );
  });

  test('existing accounts and guardians are not blocked by the new step', () {
    expect(
      resolveRequiredOnboardingPath(
        student.copyWith(
          onboardingCompletedAt: DateTime.utc(2026, 11, 1),
          voice: 'Bass',
          choir: 'Konzertchor',
        ),
      ),
      isNull,
    );
    expect(
      resolveRequiredOnboardingPath(student.copyWith(role: 'Elternteil')),
      LoginPaths.selectChild,
    );
  });
}
