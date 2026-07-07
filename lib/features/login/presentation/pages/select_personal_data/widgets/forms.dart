import 'package:chronoapp/core/database/backend_enums.dart';
import 'package:flutter/material.dart';

import '../../../widgets/login_dropdown_field.dart';
import '../../../widgets/login_flow_spacing.dart';
import '../../../widgets/login_labeled_field.dart';
import '../../../widgets/login_personal_name_fields.dart';
import 'login_meal_images_preference_box.dart';

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
    required this.showMealImages,
    required this.classOptions,
    required this.onClassChanged,
    required this.onSchoolTrackChanged,
    required this.onDietChanged,
    required this.onShowMealImagesChanged,
  });

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
  final bool showMealImages;
  final List<String> classOptions;
  final ValueChanged<String?> onClassChanged;
  final ValueChanged<String?> onSchoolTrackChanged;
  final ValueChanged<String?> onDietChanged;
  final ValueChanged<bool> onShowMealImagesChanged;

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
            hintText: 'z. B. 10a',
            leadingIcon: const Icon(Icons.school_outlined),
            validator: (value) {
              if (classOptions.isEmpty) {
                return 'Keine Klassen verfuegbar. Bitte spaeter erneut versuchen.';
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
        SizedBox(height: blockGap),
        LoginMealImagesPreferenceBox(
          showMealImages: showMealImages,
          onChanged: onShowMealImagesChanged,
        ),
      ],
    );
  }
}
