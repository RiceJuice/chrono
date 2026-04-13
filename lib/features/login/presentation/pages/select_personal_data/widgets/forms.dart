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
    final ColorScheme scheme = Theme.of(context).colorScheme;

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
        FormField<String>(
          initialValue: selectedClass,
          validator: (value) {
            if (classOptions.isEmpty) {
              return 'Keine Klassen verfuegbar. Bitte spaeter erneut versuchen.';
            }
            if (value == null || value.trim().isEmpty) {
              return 'Bitte eine Klasse auswaehlen.';
            }
            return null;
          },
          builder: (FormFieldState<String> field) {
            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double w = constraints.maxWidth;
                return DropdownMenu<String>(
                  width: w,
                  menuHeight: loginDropdownMenuMaxHeight(context),
                  menuStyle: loginDropdownMenuSurfaceStyle(context),
                  decorationBuilder: (BuildContext context, MenuController _) {
                    assert(debugCheckHasMaterial(context));
                    return loginDropdownDecorationWithOpenHaptic(
                      loginInputDecoration('Klasse').copyWith(
                        hintText: 'Klasse auswählen',
                        hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
                        errorText: field.errorText,
                      ),
                    );
                  },
                  initialSelection: field.value,
                  onSelected: (String? value) {
                    if (value != null) {
                      loginDropdownSelectionHaptic();
                    }
                    field.didChange(value);
                    onClassChanged(value);
                  },
                  enableSearch: false,
                  enableFilter: false,
                  selectOnly: true,
                  textStyle: TextStyle(color: scheme.onSurface),
                  trailingIcon: Icon(Icons.arrow_drop_down, color: scheme.onSurface),
                  dropdownMenuEntries: loginDropdownMenuEntries<String>(
                    context,
                    classOptions,
                    width: w,
                    labelOf: (String v) => v,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

