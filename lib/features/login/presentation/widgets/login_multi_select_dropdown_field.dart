import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:flutter/material.dart';

import 'login_input_decoration.dart';

/// Mehrfachauswahl im Login-Stil: Trigger wie ein Dropdown, Auswahl per Checkbox-Sheet.
class LoginMultiSelectDropdownField extends StatelessWidget {
  const LoginMultiSelectDropdownField({
    super.key,
    required this.options,
    required this.selectedValues,
    required this.onChanged,
    this.label = 'Auswählen',
    this.hintText = 'Bitte auswählen',
    this.leadingIcon,
    this.validator,
    this.formFieldKey,
    this.sheetTitle = 'Auswahl',
    this.emptyOptionsMessage = 'Keine Optionen verfügbar.',
  });

  final List<String> options;
  final List<String> selectedValues;
  final ValueChanged<List<String>> onChanged;
  final String label;
  final String hintText;
  final Widget? leadingIcon;
  final String? Function(List<String>?)? validator;
  final GlobalKey<FormFieldState<dynamic>>? formFieldKey;
  final String sheetTitle;
  final String emptyOptionsMessage;

  static String displayLabelFor(List<String> selected) {
    if (selected.isEmpty) return '';
    if (selected.length == 1) return selected.first;
    return '${selected.length} ausgewählt';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mutedColor = scheme.onSurfaceVariant.withValues(alpha: 0.7);
    final isEnabled = options.isNotEmpty;
    final displayText = displayLabelFor(selectedValues);

    return FormField<List<String>>(
      key: formFieldKey,
      initialValue: selectedValues,
      validator: validator,
      builder: (field) {
        final errorText = field.errorText;
        final decoration = loginInputDecoration(context, label).copyWith(
          hintText: hintText,
          errorText: errorText,
          prefixIcon: leadingIcon ??
              Icon(Icons.school_outlined, color: mutedColor),
          suffixIcon: Icon(Icons.arrow_drop_down, color: mutedColor),
        );

        return InkWell(
          onTap: !isEnabled
              ? null
              : () => _openSheet(context, field),
          borderRadius: decoration.border is OutlineInputBorder
              ? (decoration.border as OutlineInputBorder).borderRadius
              : BorderRadius.circular(12),
          child: InputDecorator(
            decoration: decoration,
            isEmpty: displayText.isEmpty,
            child: Text(
              displayText.isEmpty ? hintText : displayText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: displayText.isEmpty
                        ? scheme.onSurfaceVariant.withValues(alpha: 0.55)
                        : scheme.onSurface,
                  ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openSheet(
    BuildContext context,
    FormFieldState<List<String>> field,
  ) async {
    if (options.isEmpty) return;

    final result = await AppModalSheet.show<List<String>>(
      context: context,
      builder: (context) => _LoginMultiSelectSheet(
        title: sheetTitle,
        options: options,
        initialSelection: List<String>.from(selectedValues),
        emptyMessage: emptyOptionsMessage,
      ),
    );

    if (result == null) return;
    field.didChange(result);
    onChanged(result);
  }
}

class _LoginMultiSelectSheet extends StatefulWidget {
  const _LoginMultiSelectSheet({
    required this.title,
    required this.options,
    required this.initialSelection,
    required this.emptyMessage,
  });

  final String title;
  final List<String> options;
  final List<String> initialSelection;
  final String emptyMessage;

  @override
  State<_LoginMultiSelectSheet> createState() => _LoginMultiSelectSheetState();
}

class _LoginMultiSelectSheetState extends State<_LoginMultiSelectSheet> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.initialSelection);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            if (widget.options.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  widget.emptyMessage,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final option in widget.options)
                      CheckboxListTile(
                        value: _selected.contains(option),
                        title: Text(option),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selected.add(option);
                            } else {
                              _selected.remove(option);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _selected.isEmpty
                  ? null
                  : () => Navigator.of(context).pop(_selected.toList()..sort()),
              child: const Text('Fertig'),
            ),
          ],
        ),
      ),
    );
  }
}
