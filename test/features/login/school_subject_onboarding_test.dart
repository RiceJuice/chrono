import 'package:chronoapp/features/login/presentation/pages/select_personal_data/widgets/forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'onboarding restores selected subjects and validates missing choices',
    (tester) async {
      final formKey = GlobalKey<FormState>();
      final first = TextEditingController(text: 'Max');
      final last = TextEditingController(text: 'Muster');
      addTearDown(first.dispose);
      addTearDown(last.dispose);
      Future<void> show({
        String? language,
        String? arts,
        String cohort = '11a',
        String track = 'NTG',
      }) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: LoginPersonalDataFields(
                  firstNameFieldKey: GlobalKey(),
                  lastNameFieldKey: GlobalKey(),
                  classFieldKey: GlobalKey(),
                  schoolTrackFieldKey: GlobalKey(),
                  dietFieldKey: GlobalKey(),
                  firstNameController: first,
                  lastNameController: last,
                  selectedClass: cohort,
                  selectedSchoolTrack: track,
                  selectedDiet: 'Vegetarisch',
                  selectedLanguageSubject: language,
                  selectedArtsSubject: arts,
                  classOptions: ['10a', '11a'],
                  onClassChanged: (_) {},
                  onSchoolTrackChanged: (_) {},
                  onDietChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await show(language: 'Französisch', arts: 'Musik');
      expect(find.text('Französisch'), findsWidgets);
      expect(find.text('Musik'), findsWidgets);
      expect(formKey.currentState!.validate(), isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      await show();
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Bitte wähle deine Fremdsprache aus.'), findsOneWidget);
      expect(find.text('Bitte wähle Kunst oder Musik aus.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await show(cohort: '10a');
      expect(formKey.currentState!.validate(), isTrue);
      expect(find.text('Fremdsprache'), findsNothing);
    },
  );
}
