import 'package:flutter/material.dart';

/// Server-seitige Fehlermeldungen, die unter Formularfeldern angezeigt werden.
class LoginFormFieldErrors {
  final Map<Object, String> _messages = {};

  /// Kombiniert einen Client-Validator mit einer ggf. gesetzten Server-Meldung.
  String? Function(String?) merge(
    Object fieldId,
    String? Function(String?) clientValidator,
  ) {
    return (String? value) {
      final server = _messages[fieldId];
      if (server != null) return server;
      return clientValidator(value);
    };
  }

  void set(
    BuildContext context, {
    required Object fieldId,
    required GlobalKey<FormFieldState<dynamic>> fieldKey,
    required String message,
    required VoidCallback onRebuild,
    GlobalKey<FormState>? formKey,
  }) {
    _messages[fieldId] = message;
    onRebuild();
    formKey?.currentState?.validate();
    loginScrollToField(context, fieldKey);
  }

  bool clear(Object fieldId) => _messages.remove(fieldId) != null;

  void clearAll() => _messages.clear();
}

/// Scrollt ein Formularfeld in den sichtbaren Bereich.
void loginScrollToField(
  BuildContext context,
  GlobalKey<FormFieldState<dynamic>> fieldKey, {
  double alignment = 0.2,
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    final BuildContext? targetContext = fieldKey.currentContext;
    if (targetContext == null) return;
    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: alignment,
    );
  });
}

/// Leitet Auth-Fehlermeldungen auf ein passendes Formularfeld.
GlobalKey<FormFieldState<dynamic>> loginResolveAuthErrorFieldKey(
  String message, {
  GlobalKey<FormFieldState<dynamic>>? emailFieldKey,
  required GlobalKey<FormFieldState<dynamic>> passwordFieldKey,
  GlobalKey<FormFieldState<dynamic>>? newPasswordFieldKey,
  GlobalKey<FormFieldState<dynamic>>? currentPasswordFieldKey,
}) {
  final lower = message.toLowerCase();

  if (newPasswordFieldKey != null &&
      (lower.contains('unterscheiden') ||
          lower.contains('schwach') ||
          lower.contains('zu kurz') ||
          lower.contains('same password'))) {
    return newPasswordFieldKey;
  }

  if (currentPasswordFieldKey != null) {
    return currentPasswordFieldKey;
  }

  if (emailFieldKey != null &&
      (lower.contains('e-mail') ||
          lower.contains('email') ||
          lower.contains('registriert'))) {
    return emailFieldKey;
  }

  return passwordFieldKey;
}

/// Zeigt eine Auth-Fehlermeldung unter dem passenden Formularfeld an.
void loginShowAuthFormError(
  BuildContext context, {
  required String message,
  required LoginFormFieldErrors fieldErrors,
  required Object fieldId,
  required GlobalKey<FormFieldState<dynamic>> fieldKey,
  required GlobalKey<FormState> formKey,
  required VoidCallback onRebuild,
}) {
  fieldErrors.set(
    context,
    fieldId: fieldId,
    fieldKey: fieldKey,
    message: message,
    formKey: formKey,
    onRebuild: onRebuild,
  );
}

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
      loginScrollToField(context, key);
      return;
    }
  });

  return false;
}
