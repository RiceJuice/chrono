import 'package:chronoapp/core/widgets/app_glass_back_button.dart';
import 'package:chronoapp/core/widgets/main_shell_scaffold.dart';
import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:chronoapp/features/login/data/auth_repository.dart';
import 'package:chronoapp/features/login/presentation/providers/auth_repository_provider.dart';
import 'package:chronoapp/features/login/presentation/utils/login_form_validation.dart';
import 'package:chronoapp/features/login/presentation/widgets/buttons.dart';
import 'package:chronoapp/features/login/presentation/widgets/login_flow_spacing.dart';
import 'package:chronoapp/features/login/presentation/widgets/login_labeled_field.dart';
import 'package:chronoapp/features/login/presentation/widgets/login_scroll_surface.dart';
import 'package:chronoapp/features/login/presentation/widgets/login_step_scaffold.dart';
import 'package:chronoapp/features/login/presentation/widgets/login_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsChangePasswordPage extends ConsumerStatefulWidget {
  const SettingsChangePasswordPage({super.key});

  @override
  ConsumerState<SettingsChangePasswordPage> createState() =>
      _SettingsChangePasswordPageState();
}

class _SettingsChangePasswordPageState
    extends ConsumerState<SettingsChangePasswordPage> {
  static const _currentPasswordFieldId = Object();
  static const _newPasswordFieldId = Object();

  final _formKey = GlobalKey<FormState>();
  final _fieldErrors = LoginFormFieldErrors();
  final _currentPasswordFieldKey = GlobalKey<FormFieldState<dynamic>>();
  final _newPasswordFieldKey = GlobalKey<FormFieldState<dynamic>>();
  final _newPasswordConfirmFieldKey = GlobalKey<FormFieldState<dynamic>>();
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _newPasswordConfirmController;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _newPasswordConfirmController = TextEditingController();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _newPasswordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final ok = loginValidateFormAndScrollToFirstError(
      context,
      formKey: _formKey,
      orderedFieldKeys: [
        _currentPasswordFieldKey,
        _newPasswordFieldKey,
        _newPasswordConfirmFieldKey,
      ],
    );
    if (!ok) return;

    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          );
      if (!mounted) return;
      showAppToast(
        context,
        'Passwort wurde geändert.',
        kind: AppToastKind.success,
      );
      Navigator.of(context).pop();
    } on AuthRepositoryException catch (e) {
      if (mounted) {
        _showError(e.message);
      }
    } catch (_) {
      if (mounted) {
        _showError(
          'Passwort konnte nicht geändert werden. Bitte erneut versuchen.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    final fieldKey = loginResolveAuthErrorFieldKey(
      message,
      passwordFieldKey: _newPasswordFieldKey,
      newPasswordFieldKey: _newPasswordFieldKey,
      currentPasswordFieldKey: _currentPasswordFieldKey,
    );
    final fieldId = fieldKey == _newPasswordFieldKey
        ? _newPasswordFieldId
        : _currentPasswordFieldId;
    loginShowAuthFormError(
      context,
      message: message,
      fieldErrors: _fieldErrors,
      fieldId: fieldId,
      fieldKey: fieldKey,
      formKey: _formKey,
      onRebuild: () => setState(() {}),
    );
  }

  void _onFieldEdited(Object fieldId) {
    if (_fieldErrors.clear(fieldId)) {
      setState(() {});
      _formKey.currentState?.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titleStyle = GoogleFonts.libreBaskerville(
      color: scheme.onSurface,
      fontSize: 44,
      fontWeight: FontWeight.w700,
    );
    final fieldGap = LoginFlowSpacing.gapBetweenFields(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppGlassBackButton(enabled: !_busy),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: LoginStepScaffold.defaultContentMaxWidth,
                  ),
                  child: Text(
                    'Passwort ändern',
                    textAlign: TextAlign.left,
                    style: titleStyle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: LoginScrollSurface(
                scrollPadding: const EdgeInsets.only(bottom: 16),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: LoginStepScaffold.defaultContentMaxWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LoginLabeledField(
                              label: 'Aktuelles Passwort',
                              child: LoginTextField(
                                formFieldKey: _currentPasswordFieldKey,
                                controller: _currentPasswordController,
                                hintText: 'Aktuelles Passwort eingeben',
                                obscureText: true,
                                showPasswordVisibilityToggle: true,
                                validator: _fieldErrors.merge(
                                  _currentPasswordFieldId,
                                  (value) {
                                    final input = value ?? '';
                                    if (input.isEmpty) {
                                      return 'Bitte aktuelles Passwort eingeben.';
                                    }
                                    return null;
                                  },
                                ),
                                onChanged: (_) =>
                                    _onFieldEdited(_currentPasswordFieldId),
                              ),
                            ),
                            SizedBox(height: fieldGap),
                            LoginLabeledField(
                              label: 'Neues Passwort',
                              child: LoginTextField(
                                formFieldKey: _newPasswordFieldKey,
                                controller: _newPasswordController,
                                hintText: 'Neues Passwort eingeben',
                                obscureText: true,
                                showPasswordVisibilityToggle: true,
                                validator: _fieldErrors.merge(
                                  _newPasswordFieldId,
                                  (value) {
                                    final input = value ?? '';
                                    if (input.isEmpty) {
                                      return 'Bitte neues Passwort eingeben.';
                                    }
                                    if (input.length < 8) {
                                      return 'Passwort muss mindestens 8 Zeichen haben.';
                                    }
                                    return null;
                                  },
                                ),
                                onChanged: (_) =>
                                    _onFieldEdited(_newPasswordFieldId),
                              ),
                            ),
                            SizedBox(height: fieldGap),
                            LoginLabeledField(
                              label: 'Neues Passwort wiederholen',
                              child: LoginTextField(
                                formFieldKey: _newPasswordConfirmFieldKey,
                                controller: _newPasswordConfirmController,
                                hintText: 'Neues Passwort bestätigen',
                                obscureText: true,
                                showPasswordVisibilityToggle: true,
                                validator: (value) {
                                  final input = value ?? '';
                                  if (input.isEmpty) {
                                    return 'Bitte neues Passwort bestätigen.';
                                  }
                                  if (input != _newPasswordController.text) {
                                    return 'Passwörter stimmen nicht überein.';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                16 + kMainShellNavigationBarHeight,
              ),
              child: Align(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: LoginStepScaffold.defaultContentMaxWidth,
                  ),
                  child: LoginPrimaryButton(
                    label: 'Speichern',
                    color: scheme.primary,
                    isLoading: _busy,
                    onPressed: _busy ? null : _onSave,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
