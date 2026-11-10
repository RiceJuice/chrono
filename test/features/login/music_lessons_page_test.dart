import 'dart:async';

import 'package:chronoapp/features/login/domain/models/profile_gate_data.dart';
import 'package:chronoapp/features/login/presentation/providers/profile_gate_notifier.dart';
import 'package:chronoapp/features/login/presentation/providers/profile_gate_provider.dart';
import 'package:chronoapp/features/login/presentation/routes/login_routes.dart';
import 'package:chronoapp/features/music_lessons/domain/music_lesson_schedule.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class _ProfileGate extends Fake implements ProfileGateNotifier {
  _ProfileGate({this.schedule});

  final MusicLessonSchedule? schedule;
  final requests = <({MusicLesson? voice, MusicLesson? instrument})>[];
  Future<void> Function()? onSave;

  @override
  ProfileGateData get data =>
      const ProfileGateData.signedOut().copyWith(musicLessons: schedule);

  @override
  Future<void> saveMusicLessons({
    MusicLesson? voice,
    MusicLesson? instrument,
  }) async {
    requests.add((voice: voice, instrument: instrument));
    await onSave?.call();
  }
}

void main() {
  const channel = MethodChannel('chrono/music_lesson_editor');

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpFlow(WidgetTester tester, _ProfileGate gate) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: LoginPaths.musicLessons,
      routes: loginRoutes,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [profileGateProvider.overrideWithValue(gate)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Apple editor returns a lesson, then save waits and opens choir',
    (tester) async {
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'present');
        expect(call.arguments['hasInstrument'], isTrue);
        expect(call.arguments['instruments'], contains('Klavier'));
        return {
          'weekday': 4,
          'startMinute': 870,
          'instrument': 'Klavier',
          'teacher': 'Frau Weber',
          'extended': true,
        };
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      final gate = _ProfileGate();
      final saving = Completer<void>();
      gate.onSave = () => saving.future;
      await pumpFlow(tester, gate);

      expect(find.text('Wochentag'), findsNothing);
      expect(find.text('Speichern & weiter'), findsNothing);
      await tester.tap(find.text('Instrumentalunterricht'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Klavier · Donnerstag, 14:30 Uhr'),
        findsOneWidget,
      );

      await tester.tap(find.text('Speichern & weiter'));
      await tester.pump();
      expect(gate.requests, hasLength(1));
      expect(gate.requests.single.instrument?.durationMinutes, 45);
      expect(gate.requests.single.instrument?.teacher, 'Frau Weber');
      expect(find.text('Dein Chor'), findsNothing);
      saving.complete();
      await tester.pumpAndSettle();
      expect(find.text('Dein Chor'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'clock selects hours and individual minutes in separate steps',
    (tester) async {
      final gate = _ProfileGate();
      await pumpFlow(tester, gate);

      await tester.tap(find.text('Stimmbildung'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Di'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Beginn wählen'));
      await tester.pumpAndSettle();

      expect(find.text('Stunde wählen'), findsOneWidget);
      expect(find.bySemanticsLabel('25 Minuten'), findsNothing);
      await tester.tap(find.text('16'));
      await tester.pumpAndSettle();

      expect(find.text('Minute wählen'), findsOneWidget);
      expect(find.bySemanticsLabel('16 Uhr'), findsNothing);
      await tester.tap(find.text('25'));
      await tester.tap(find.byTooltip('Eine Minute vor'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Übernehmen'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('16:26 Uhr'), findsOneWidget);
      await tester.tap(find.text('Übernehmen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Speichern & weiter'));
      await tester.pumpAndSettle();
      expect(gate.requests.single.voice?.startMinute, 16 * 60 + 26);
      expect(find.text('Dein Chor'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets('failed save stays on the screen and can be retried', (
    tester,
  ) async {
    final gate = _ProfileGate(
      schedule: MusicLessonSchedule(
        startsOn: DateTime.utc(2026, 11, 10),
        voice: const MusicLesson(
          kind: MusicLessonKind.voice,
          weekday: 2,
          startMinute: 810,
        ),
      ),
    );
    gate.onSave = () async => throw StateError('network unavailable');
    await pumpFlow(tester, gate);
    expect(find.text('Wochentag'), findsNothing);
    expect(find.textContaining('Dienstag, 13:30 Uhr'), findsOneWidget);

    await tester.tap(find.text('Speichern & weiter'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Das Speichern hat nicht geklappt'),
      findsOneWidget,
    );
    expect(find.text('Dein Chor'), findsNothing);
    expect(find.textContaining('Dienstag, 13:30 Uhr'), findsOneWidget);

    gate.onSave = null;
    await tester.tap(find.text('Speichern & weiter'));
    await tester.pumpAndSettle();
    expect(gate.requests, hasLength(2));
    expect(find.text('Dein Chor'), findsOneWidget);
  });
}
