import 'package:chronoapp/features/login/domain/models/profile_gate_data.dart';
import 'package:chronoapp/features/login/presentation/providers/profile_gate_notifier.dart';
import 'package:chronoapp/features/login/presentation/providers/profile_gate_provider.dart';
import 'package:chronoapp/features/music_lessons/domain/music_lesson_schedule.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_music_lessons_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _ProfileGate extends ChangeNotifier implements ProfileGateNotifier {
  MusicLessonSchedule schedule = MusicLessonSchedule(
    startsOn: DateTime.utc(2026, 11, 10),
    voice: const MusicLesson(
      kind: MusicLessonKind.voice,
      weekday: 2,
      startMinute: 825,
    ),
    instrument: const MusicLesson(
      kind: MusicLessonKind.instrument,
      weekday: 4,
      startMinute: 870,
      instrument: 'Klavier',
    ),
  );

  @override
  ProfileGateData get data => const ProfileGateData.signedOut().copyWith(
    hasSession: true,
    role: 'Schüler',
    musicLessons: schedule,
  );

  @override
  Future<void> saveMusicLesson(
    MusicLessonKind kind,
    MusicLesson? lesson,
  ) async {
    schedule = MusicLessonSchedule(
      startsOn: schedule.startsOn,
      voice: kind == MusicLessonKind.voice ? lesson : schedule.voice,
      instrument: kind == MusicLessonKind.instrument
          ? lesson
          : schedule.instrument,
    );
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'settings prefill a saved lesson and update only the selected entry',
    (tester) async {
      final gate = _ProfileGate();
      addTearDown(gate.dispose);
      const channel = MethodChannel('chrono/music_lesson_editor');
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'present');
        if (call.arguments['hasInstrument'] == true) {
          expect(call.arguments['instrument'], 'Klavier');
          return {'remove': true};
        }
        expect(call.arguments['weekday'], 2);
        expect(call.arguments['startMinute'], 825);
        return {'weekday': 3, 'startMinute': 840, 'extended': true};
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [profileGateProvider.overrideWithValue(gate)],
          child: const MaterialApp(
            home: Scaffold(body: SettingsMusicLessonsSection()),
          ),
        ),
      );

      expect(find.text('Di, 13:45 Uhr'), findsOneWidget);
      expect(find.text('Do, 14:30 Uhr'), findsOneWidget);

      await tester.tap(find.text('Stimmbildung'));
      await tester.pumpAndSettle();
      expect(find.text('Mi, 14:00 Uhr'), findsOneWidget);
      expect(find.text('Do, 14:30 Uhr'), findsOneWidget);
      expect(gate.schedule.voice?.durationMinutes, 45);

      await tester.tap(find.text('Instrumentalunterricht'));
      await tester.pumpAndSettle();
      expect(find.text('Eintragen'), findsOneWidget);
      expect(find.text('Mi, 14:00 Uhr'), findsOneWidget);
      expect(gate.schedule.instrument, isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
