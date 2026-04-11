import 'package:flutter/material.dart';

import '../../../widgets/login_dropdown_menu.dart';
import '../../../widgets/login_input_decoration.dart';
import '../../../widgets/login_text_field.dart';

class LoginPersonalDataFields extends StatelessWidget {
  const LoginPersonalDataFields({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.selectedClass,
    required this.classOptions,
    required this.onClassChanged,
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final String? selectedClass;
  final List<String> classOptions;
  final ValueChanged<String?> onClassChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoginTextField(
          controller: firstNameController,
          hintText: 'Vorname',
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return 'Bitte Vornamen eingeben.';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),
        LoginTextField(
          controller: lastNameController,
          hintText: 'Nachname',
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return 'Bitte Nachnamen eingeben.';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double w = constraints.maxWidth;
            return DropdownMenuFormField<String>(
              width: w,
              menuHeight: loginDropdownMenuMaxHeight(context),
              menuStyle: loginDropdownMenuSurfaceStyle(),
              hintText: 'Klasse auswählen',
              decorationBuilder: (BuildContext context, MenuController _) {
                assert(debugCheckHasMaterial(context));
                return loginInputDecoration('Klasse');
              },
              initialSelection: selectedClass,
              onSelected: onClassChanged,
              enableSearch: false,
              enableFilter: false,
              textStyle: const TextStyle(color: Colors.white),
              enabled: classOptions.isNotEmpty,
              dropdownMenuEntries: loginDropdownMenuEntries<String>(
                classOptions,
                width: w,
                labelOf: (String v) => v,
              ),
              validator: (String? value) {
                if (classOptions.isEmpty) {
                  return 'Keine Klassen verfuegbar. Bitte spaeter erneut versuchen.';
                }
                if (value == null || value.trim().isEmpty) {
                  return 'Bitte eine Klasse auswaehlen.';
                }
                return null;
              },
            );
          },
        ),
      ],
    );
  }
}

