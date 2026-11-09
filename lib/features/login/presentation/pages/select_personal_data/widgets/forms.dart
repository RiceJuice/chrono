import 'package:chronoapp/core/database/backend_enums.dart';
import 'package:flutter/material.dart';
import 'package:chronoapp/core/database/arts_subject.dart';

import '../../../widgets/login_dropdown_field.dart';
import '../../../widgets/login_flow_spacing.dart';
import '../../../widgets/login_labeled_field.dart';
import '../../../widgets/login_personal_name_fields.dart';

final loginDietOptions = <String>[
  BackendDiet.noRestriction.displayLabel,
  BackendDiet.vegetarian.displayLabel,
];

class LoginPersonalDataFields extends StatelessWidget {
  const LoginPersonalDataFields({
    super.key,
    required this.firstNameFieldKey,
    required this.lastNameFieldKey,
    required this.classFieldKey,
    required this.schoolTrackFieldKey,
    required this.dietFieldKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.selectedClass,
    required this.selectedSchoolTrack,
    required this.selectedDiet,
    required this.classOptions,
    required this.onClassChanged,
    required this.onSchoolTrackChanged,
    required this.onDietChanged,
    this.classesLoading = false,
    this.onReloadClasses,
    this.artsSubjectFieldKey,
    this.languageSubjectFieldKey,
    this.selectedArtsSubject,
    this.selectedLanguageSubject,
    this.onArtsSubjectChanged,
    this.onLanguageSubjectChanged,
  });

  final bool classesLoading;
  final VoidCallback? onReloadClasses;
  final GlobalKey<FormFieldState<dynamic>> firstNameFieldKey;
  final GlobalKey<FormFieldState<dynamic>> lastNameFieldKey;
  final GlobalKey<FormFieldState<dynamic>> classFieldKey;
  final GlobalKey<FormFieldState<dynamic>> schoolTrackFieldKey;
  final GlobalKey<FormFieldState<dynamic>> dietFieldKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final String? selectedClass;
  final String? selectedSchoolTrack;
  final String? selectedDiet;
  final GlobalKey<FormFieldState<dynamic>>? artsSubjectFieldKey;
  final GlobalKey<FormFieldState<dynamic>>? languageSubjectFieldKey;
  final String? selectedArtsSubject;
  final String? selectedLanguageSubject;
  final ValueChanged<String?>? onArtsSubjectChanged;
  final ValueChanged<String?>? onLanguageSubjectChanged;
  final List<String> classOptions;
  final ValueChanged<String?> onClassChanged;
  final ValueChanged<String?> onSchoolTrackChanged;
  final ValueChanged<String?> onDietChanged;

  @override
  Widget build(BuildContext context) {
    final double blockGap = LoginFlowSpacing.gapBetweenFields(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LoginPersonalNameFields(
          firstNameFieldKey: firstNameFieldKey,
          lastNameFieldKey: lastNameFieldKey,
          firstNameController: firstNameController,
          lastNameController: lastNameController,
        ),
        SizedBox(height: blockGap),
        LoginLabeledField(
          label: 'Klasse',
          child: LoginDropdownField(
            formFieldKey: classFieldKey,
            selectedValue: selectedClass,
            options: classOptions,
            label: 'Klasse',
            hintText: classesLoading
                ? 'Klassen werden geladen …'
                : 'Klasse auswählen',
            leadingIcon: const Icon(Icons.school_outlined),
            validator: (value) {
              if (classOptions.isEmpty) {
                return classesLoading
                    ? 'Klassen werden noch geladen.'
                    : 'Klassen konnten nicht geladen werden. Bitte erneut laden.';
              }
              if (value == null || value.trim().isEmpty) {
                return 'Bitte eine Klasse auswaehlen.';
              }
              return null;
            },
            onChanged: onClassChanged,
          ),
        ),
        SizedBox(height: blockGap),
        if (classOptions.isEmpty && !classesLoading)
          TextButton.icon(
            onPressed: onReloadClasses,
            icon: const Icon(Icons.refresh),
            label: const Text('Klassen erneut laden'),
          ),
        LoginLabeledField(
          label: 'Schulzweig',
          child: LoginDropdownField(
            formFieldKey: schoolTrackFieldKey,
            selectedValue: selectedSchoolTrack,
            options: BackendSchoolTrack.values
                .where((value) => value != BackendSchoolTrack.unknown)
                .map((value) => value.displayLabel)
                .toList(growable: false),
            label: 'Schulzweig',
            hintText: 'NTG oder Musisch',
            leadingIcon: const Icon(Icons.account_tree_outlined),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Bitte einen Schulzweig auswaehlen.';
              }
              return null;
            },
            onChanged: onSchoolTrackChanged,
          ),
        ),
        SizedBox(height: blockGap),
        if (requiresLanguageSubject(selectedClass)) ...[
          LoginLabeledField(
            label: 'Fremdsprache',
            child: LoginDropdownField(
              key: ValueKey('language-$selectedClass'),
              formFieldKey: languageSubjectFieldKey,
              selectedValue: selectedLanguageSubject,
              options: languageSubjectOptions,
              label: 'Fremdsprache',
              hintText: 'Latein oder Französisch',
              validator: (value) => hasValidLanguageSubject(value)
                  ? null
                  : 'Bitte wähle deine Fremdsprache aus.',
              onChanged: onLanguageSubjectChanged ?? (_) {},
            ),
          ),
          SizedBox(height: blockGap),
        ],
        if (requiresArtsSubject(selectedClass, selectedSchoolTrack)) ...[
          LoginLabeledField(
            label: 'Kunst / Musik',
            child: LoginDropdownField(
              key: ValueKey('arts-$selectedClass-$selectedSchoolTrack'),
              formFieldKey: artsSubjectFieldKey,
              selectedValue: selectedArtsSubject,
              options: artsSubjectOptions,
              label: 'Kunst / Musik',
              hintText: 'Kunst oder Musik',
              validator: (value) => hasValidArtsSubject(value)
                  ? null
                  : 'Bitte wähle Kunst oder Musik aus.',
              onChanged: onArtsSubjectChanged ?? (_) {},
            ),
          ),
          SizedBox(height: blockGap),
        ],
        LoginLabeledField(
          label: 'Ernährung',
          child: LoginDropdownField(
            formFieldKey: dietFieldKey,
            selectedValue: selectedDiet,
            options: loginDietOptions,
            label: 'Ernährung',
            hintText: 'Vegetarisch oder keine Einschränkung',
            leadingIcon: const Icon(Icons.restaurant_outlined),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Bitte eine Ernährung auswaehlen.';
              }
              return null;
            },
            onChanged: onDietChanged,
          ),
        ),
      ],
    );
  }
}
