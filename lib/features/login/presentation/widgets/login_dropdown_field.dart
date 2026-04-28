import 'package:flutter/material.dart';

import 'login_dropdown_menu.dart';
import 'login_input_decoration.dart';

class LoginDropdownField extends StatelessWidget {
  const LoginDropdownField({
    super.key,
    required this.selectedValue,
    required this.options,
    required this.onChanged,
    required this.hintText,
    this.label = 'Auswählen',
    this.leadingIcon,
    this.validator,
    this.formFieldKey,
  });

  final String? selectedValue;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final String hintText;
  final String label;
  final Widget? leadingIcon;
  final String? Function(String?)? validator;
  final GlobalKey<FormFieldState<dynamic>>? formFieldKey;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color mutedColor = scheme.onSurfaceVariant.withValues(alpha: 0.7);
    final bool isEnabled = options.isNotEmpty;
    const fieldContentPadding = EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 15,
    );

    return FormField<String>(
      key: formFieldKey,
      initialValue: selectedValue,
      validator: validator,
      builder: (FormFieldState<String> field) {
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double width = constraints.maxWidth;
            return DropdownMenu<String>(
              width: width,
              enabled: isEnabled,
              menuHeight: loginDropdownMenuMaxHeight(context),
              menuStyle: loginDropdownMenuSurfaceStyle(context),
              decorationBuilder: (BuildContext context, MenuController _) {
                assert(debugCheckHasMaterial(context));
                final Widget rawLeading =
                    leadingIcon ??
                    Icon(Icons.arrow_drop_down, color: mutedColor);
                final Widget mutedLeadingIcon = switch (rawLeading) {
                  Icon icon => Icon(
                    icon.icon,
                    color: mutedColor,
                    size: icon.size,
                    semanticLabel: icon.semanticLabel,
                    textDirection: icon.textDirection,
                    fill: icon.fill,
                    weight: icon.weight,
                    grade: icon.grade,
                    opticalSize: icon.opticalSize,
                    applyTextScaling: icon.applyTextScaling,
                    shadows: icon.shadows,
                    blendMode: icon.blendMode,
                  ),
                  _ => rawLeading,
                };
                return loginDropdownDecorationWithOpenHaptic(
                  loginInputDecoration(context, label).copyWith(
                    hintText: hintText,
                    hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
                    contentPadding: fieldContentPadding,
                    prefixIcon: mutedLeadingIcon,
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
                onChanged(value);
              },
              enableSearch: false,
              enableFilter: false,
              selectOnly: true,
              textStyle: TextStyle(
                color: isEnabled ? scheme.onSurface : mutedColor,
              ),
              trailingIcon: Icon(Icons.arrow_drop_down, color: mutedColor),
              dropdownMenuEntries: loginDropdownMenuEntries<String>(
                context,
                options,
                width: width,
                labelOf: (String v) => v,
              ),
            );
          },
        );
      },
    );
  }
}
