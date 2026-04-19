import 'package:flutter/material.dart';

/// Validiert das Formular unter [formKey] und scrollt das erste Feld mit
/// Validierungsfehler in den sichtbaren Bereich.
///
/// [orderedFieldKeys] in visueller Reihenfolge von oben nach unten; Felder,
/// die im aktuellen Build nicht existieren, können weggelassen werden.
bool loginValidateFormAndScrollToFirstError(
  BuildContext context, {
  required GlobalKey<FormState> formKey,
  required List<GlobalKey<FormFieldState<dynamic>>> orderedFieldKeys,
}) {
  final bool isValid = formKey.currentState?.validate() ?? false;
  if (isValid) return true;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    for (final GlobalKey<FormFieldState<dynamic>> key in orderedFieldKeys) {
      if (!(key.currentState?.hasError ?? false)) continue;
      final BuildContext? targetContext = key.currentContext;
      if (targetContext == null) return;
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: 0.2,
      );
      return;
    }
  });

  return false;
}
