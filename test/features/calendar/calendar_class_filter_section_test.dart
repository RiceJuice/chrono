import 'package:chronoapp/features/calendar/presentation/widgets/calendar_header/calendar_class_filter_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('search preserves multiple selections until confirmed', (
    tester,
  ) async {
    final selected = <String>['5a'];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarClassFilterSection(
            selectedValues: selected,
            options: const ['5a', '6b', '11a'],
            onClear: selected.clear,
            onToggle: selected.add,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Klassen auswählen'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '11');
    await tester.pumpAndSettle();
    expect(find.text('6B'), findsNothing);
    await tester.tap(find.text('11A'));
    await tester.pumpAndSettle();
    expect(selected, ['5a']);
    await tester.tap(find.text('Auswahl übernehmen'));
    await tester.pumpAndSettle();
    expect(selected, ['5a', '11a']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dismissing the picker leaves filters unchanged', (tester) async {
    var changes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarClassFilterSection(
            selectedValues: const ['5a'],
            options: const ['5a', '6b'],
            onClear: () => changes++,
            onToggle: (_) => changes++,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Klassen auswählen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alle Klassen'));
    await tester.pumpAndSettle();
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    expect(changes, 0);
  });
}
