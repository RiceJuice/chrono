import 'dart:async';

import 'package:chronoapp/features/calendar/domain/models/calendar_subject.dart';
import 'package:chronoapp/features/calendar/presentation/providers/subjects_providers.dart';
import 'package:chronoapp/features/calendar/presentation/providers/filter/calendar/calendar_filtered_entries_providers.dart';
import 'package:chronoapp/features/homework/domain/models/homework_fragment.dart';
import 'package:chronoapp/features/homework/domain/models/homework_task.dart';
import 'package:chronoapp/features/homework/presentation/providers/homework_providers.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_task_form_sheet.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_subject_section.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const subject = CalendarSubject(
    id: 'math',
    name: 'Mathematik',
    defaultColor: Colors.blue,
  );
  testWidgets('subject row opens selection and returns the selected subject', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subjectsListProvider.overrideWith((ref) => Stream.value([subject])),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: HomeworkSubjectPickerRow(
              selectedSubjectId: null,
              onSubjectChanged: (value) => selected = value,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fach auswählen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mathematik'));
    await tester.pumpAndSettle();
    expect(selected, 'math');
  });

  testWidgets('empty subject list explains missing data', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subjectsListProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: HomeworkSubjectPickerRow(
              selectedSubjectId: null,
              onSubjectChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Noch keine Fächer verfügbar'), findsOneWidget);
  });

  for (final (description, platform, nativeResult) in [
    ('Flutter toast deletes on undo', TargetPlatform.android, null),
    ('native toast deletes on undo', TargetPlatform.iOS, true),
    ('native toast keeps the task on timeout', TargetPlatform.macOS, false),
  ]) {
    testWidgets(
      'saving with a custom date: $description',
      (tester) async {
        const channel = MethodChannel('chrono/homework_date');
        const undoChannel = MethodChannel('chrono/homework_undo');
        final notifier = _RecordingHomeworkTasksNotifier();
        MethodCall? request;
        MethodCall? undoRequest;
        final undoResponse = Completer<bool>();
        final binaryMessenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        binaryMessenger.setMockMethodCallHandler(channel, (call) async {
          request = call;
          return '2027-01-15';
        });
        if (nativeResult != null) {
          binaryMessenger.setMockMethodCallHandler(undoChannel, (call) {
            undoRequest = call;
            return undoResponse.future;
          });
        }
        addTearDown(() {
          binaryMessenger.setMockMethodCallHandler(channel, null);
          binaryMessenger.setMockMethodCallHandler(undoChannel, null);
        });
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              subjectsListProvider.overrideWith(
                (ref) => Stream.value([subject]),
              ),
              currentSubjectIdProvider.overrideWithValue(null),
              homeworkTasksProvider.overrideWith(() => notifier),
              filteredCalendarAllEntriesProvider.overrideWithValue(
                const AsyncData([]),
              ),
            ],
            child: MaterialApp(
              theme: ThemeData(platform: TargetPlatform.iOS),
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => HomeworkTaskFormSheet.show(context),
                    child: const Text('Aufgabe hinzufügen'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Aufgabe erstellt'), findsNothing);
        await tester.tap(find.text('Aufgabe hinzufügen'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(CupertinoTextField).first,
          'Buch lesen',
        );
        await tester.tap(find.text('Auswählen'));
        await tester.pumpAndSettle();
        expect(request?.method, 'pickDate');
        expect(find.text('15.1.2027'), findsOneWidget);
        final button = tester.widget<CupertinoButton>(
          find.widgetWithText(CupertinoButton, 'Aufgabe speichern'),
        );
        expect(button.onPressed, isNotNull);
        await tester.drag(find.byType(ListView), const Offset(0, -180));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Aufgabe speichern'));
        await tester.pumpAndSettle();
        expect(find.byType(HomeworkTaskFormSheet), findsNothing);
        expect(notifier.deletedTaskIds, isEmpty);

        if (nativeResult == null) {
          expect(find.text('Aufgabe erstellt'), findsOneWidget);
          await tester.tap(find.text('Rückgängig'));
        } else {
          expect(undoRequest?.method, 'show');
          expect(undoRequest?.arguments, {
            'message': 'Aufgabe erstellt',
            'action': 'Rückgängig',
          });
          expect(find.text('Aufgabe erstellt'), findsNothing);
          undoResponse.complete(nativeResult);
        }
        await tester.pumpAndSettle();
        expect(
          notifier.deletedTaskIds,
          nativeResult == false ? [] : ['created-task'],
        );
        expect(find.text('Aufgabe erstellt'), findsNothing);
      },
      variant: TargetPlatformVariant({platform}),
    );
  }
}

class _RecordingHomeworkTasksNotifier extends HomeworkTasksNotifier {
  final deletedTaskIds = <String>[];

  @override
  Future<List<HomeworkTask>> build() async => [];

  @override
  Future<String?> addTask({
    String? title,
    List<HomeworkFragment> fragments = const [],
    String? description,
    String? subjectId,
    DateTime? dueAt,
    HomeworkDueSource? dueSource,
    String? contributionId,
  }) async => 'created-task';

  @override
  Future<void> deleteTask(String taskId) async {
    deletedTaskIds.add(taskId);
  }
}
