import 'package:chronoapp/features/calendar/domain/models/calendar_subject.dart';
import 'package:chronoapp/features/calendar/presentation/providers/subjects_providers.dart';
import 'package:chronoapp/features/calendar/presentation/providers/filter/calendar/calendar_filtered_entries_providers.dart';
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

  testWidgets(
    'custom date opens native picker and enables saving without a lesson',
    (tester) async {
      const channel = MethodChannel('chrono/homework_date');
      MethodCall? request;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            request = call;
            return '2027-01-15';
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subjectsListProvider.overrideWith((ref) => Stream.value([subject])),
            currentSubjectIdProvider.overrideWithValue(null),
            filteredCalendarAllEntriesProvider.overrideWithValue(
              const AsyncData([]),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(platform: TargetPlatform.iOS),
            home: const Scaffold(body: HomeworkTaskFormSheet(embedded: true)),
          ),
        ),
      );
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
    },
  );
}
