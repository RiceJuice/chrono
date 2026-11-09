import 'package:chronoapp/features/login/presentation/state/login_flow_draft.dart';
import 'package:chronoapp/features/login/presentation/pages/select_role/widgets/login_role_selection.dart';
import 'package:chronoapp/features/login/presentation/pages/select_role/widgets/login_choice_card.dart';
import 'package:chronoapp/features/login/presentation/widgets/login_dropdown_field.dart';
import 'package:chronoapp/features/calendar/presentation/providers/meal_images_preference_provider.dart';
import 'package:chronoapp/features/calendar/event_editor/presentation/providers/is_admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('fresh role selection is neutral until a role is tapped', (
    tester,
  ) async {
    final draft = LoginFlowDraft.instance..reset();
    addTearDown(draft.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => LoginRoleSelection(
              selectedRole: draft.role,
              onSelect: (role) => setState(() => draft.role = role),
            ),
          ),
        ),
      ),
    );
    expect(
      tester
          .widgetList<LoginChoiceCard>(find.byType(LoginChoiceCard))
          .every((card) => !card.isSelected),
      isTrue,
    );
    await tester.tap(find.text('Schüler'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<LoginChoiceCard>(find.byType(LoginChoiceCard))
          .where((card) => card.isSelected)
          .single
          .title,
      'Schüler',
    );
    await tester.tap(find.text('Elternteil'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<LoginChoiceCard>(find.byType(LoginChoiceCard))
          .where((card) => card.isSelected)
          .single
          .title,
      'Elternteil',
    );
  });

  testWidgets('class field and its arrow both open selectable classes', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: LoginDropdownField(
                selectedValue: null,
                options: const ['5a', '6b'],
                hintText: 'Klasse auswählen',
                label: 'Klasse',
                onChanged: (value) => selected = value,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.tap(find.text('6b').last);
    await tester.pumpAndSettle();
    expect(selected, '6b');
    await tester.tap(
      find.widgetWithIcon(IconButton, Icons.arrow_drop_down).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('5a').last);
    await tester.pumpAndSettle();
    expect(selected, '5a');
    expect(tester.takeException(), isNull);
  });

  test('meal images follow admin role and disappear on role change', () {
    final container = ProviderContainer(
      overrides: [isAdminProvider.overrideWithValue(false)],
    );
    addTearDown(container.dispose);
    expect(container.read(showMealImagesProvider), isFalse);
    container.updateOverrides([isAdminProvider.overrideWithValue(true)]);
    expect(container.read(showMealImagesProvider), isTrue);
    container.updateOverrides([isAdminProvider.overrideWithValue(false)]);
    expect(container.read(showMealImagesProvider), isFalse);
  });
}
