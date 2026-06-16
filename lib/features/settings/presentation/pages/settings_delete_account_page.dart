import 'package:chronoapp/core/push/push_notification_service.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/core/widgets/app_dialog.dart';
import 'package:chronoapp/core/widgets/app_glass_back_button.dart';
import 'package:chronoapp/core/widgets/main_shell_scaffold.dart';
import 'package:chronoapp/features/login/data/auth_repository.dart';
import 'package:chronoapp/features/login/presentation/providers/auth_repository_provider.dart';
import 'package:chronoapp/features/login/presentation/utils/login_form_validation.dart';
import 'package:chronoapp/features/login/presentation/widgets/login_flow_spacing.dart';
import 'package:chronoapp/features/login/presentation/widgets/login_labeled_field.dart';
import 'package:chronoapp/features/login/presentation/widgets/login_scroll_surface.dart';
import 'package:chronoapp/features/login/presentation/widgets/login_step_scaffold.dart';
import 'package:chronoapp/features/login/presentation/widgets/login_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const _confirmationPhrase = 'LÖSCHEN';

class SettingsDeleteAccountPage extends ConsumerStatefulWidget {
  const SettingsDeleteAccountPage({super.key});

  @override
  ConsumerState<SettingsDeleteAccountPage> createState() =>
      _SettingsDeleteAccountPageState();
}

class _SettingsDeleteAccountPageState
    extends ConsumerState<SettingsDeleteAccountPage> {
  static const _passwordFieldId = Object();
  static const _emailFieldId = Object();

  final _formKey = GlobalKey<FormState>();
  final _fieldErrors = LoginFormFieldErrors();
  final _passwordFieldKey = GlobalKey<FormFieldState<dynamic>>();
  final _emailFieldKey = GlobalKey<FormFieldState<dynamic>>();
  final _confirmationFieldKey = GlobalKey<FormFieldState<dynamic>>();
  late final TextEditingController _passwordController;
  late final TextEditingController _emailController;
  late final TextEditingController _confirmationController;
  bool _understood = false;
  bool _busy = false;

  bool get _requiresPassword =>
      ref.read(authRepositoryProvider).canChangePassword;

  String? get _accountEmail =>
      ref.read(authRepositoryProvider).currentUserEmail?.trim();

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _emailController = TextEditingController();
    _confirmationController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _emailController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (!_understood || _busy) return false;
    if (_confirmationController.text.trim() != _confirmationPhrase) return false;
    if (_requiresPassword) {
      return _passwordController.text.isNotEmpty;
    }
    final email = _accountEmail?.toLowerCase();
    return email != null &&
        _emailController.text.trim().toLowerCase() == email;
  }

  Future<void> _onDeletePressed() async {
    final ok = loginValidateFormAndScrollToFirstError(
      context,
      formKey: _formKey,
      orderedFieldKeys: [
        if (_requiresPassword) _passwordFieldKey else _emailFieldKey,
        _confirmationFieldKey,
      ],
    );
    if (!ok || !_understood) return;

    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Letzte Warnung',
      message:
          'Dein Konto und alle zugehörigen Daten werden jetzt endgültig gelöscht. '
          'Dieser Schritt ist unwiderruflich.',
      confirmLabel: 'Konto endgültig löschen',
      cancelLabel: 'Abbrechen',
      confirmRole: AppDialogActionRole.destructive,
      barrierDismissible: false,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      await PushNotificationService().clearTokenOnLogout();
      await ref.read(authRepositoryProvider).deleteAccount(
            password:
                _requiresPassword ? _passwordController.text : null,
            confirmationEmail:
                _requiresPassword ? null : _emailController.text,
          );
      if (!context.mounted) return;
      await HapticFeedback.heavyImpact();
    } on AuthRepositoryException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      _showError(
        'Konto konnte nicht gelöscht werden. Bitte erneut versuchen.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    final fieldKey = _requiresPassword
        ? loginResolveAuthErrorFieldKey(
            message,
            passwordFieldKey: _passwordFieldKey,
            currentPasswordFieldKey: _passwordFieldKey,
          )
        : _emailFieldKey;
    final fieldId = fieldKey == _passwordFieldKey
        ? _passwordFieldId
        : _emailFieldId;
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

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titleStyle = GoogleFonts.libreBaskerville(
      color: scheme.error,
      fontSize: 40,
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: LoginStepScaffold.defaultContentMaxWidth,
                  ),
                  child: Text(
                    'Konto löschen',
                    textAlign: TextAlign.left,
                    style: titleStyle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
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
                            _DangerWarningCard(scheme: scheme),
                            const SizedBox(height: 24),
                            _ConsequenceList(scheme: scheme),
                            const SizedBox(height: 24),
                            CheckboxListTile(
                              value: _understood,
                              onChanged: _busy
                                  ? null
                                  : (value) {
                                      HapticFeedback.selectionClick();
                                      setState(
                                        () => _understood = value ?? false,
                                      );
                                    },
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(
                                'Ich verstehe, dass alle meine Daten unwiderruflich gelöscht werden und ich keinen Zugriff mehr auf mein Konto habe.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: scheme.onSurface
                                          .withValues(alpha: 0.88),
                                      height: 1.45,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_requiresPassword)
                              LoginLabeledField(
                                label: 'Aktuelles Passwort',
                                child: LoginTextField(
                                  formFieldKey: _passwordFieldKey,
                                  controller: _passwordController,
                                  hintText: 'Passwort zur Bestätigung eingeben',
                                  obscureText: true,
                                  showPasswordVisibilityToggle: true,
                                  validator: _fieldErrors.merge(
                                    _passwordFieldId,
                                    (value) {
                                      final input = value ?? '';
                                      if (input.isEmpty) {
                                        return 'Bitte Passwort eingeben.';
                                      }
                                      return null;
                                    },
                                  ),
                                  onChanged: (_) {
                                    _onFieldEdited(_passwordFieldId);
                                    _onFormChanged();
                                  },
                                ),
                              )
                            else
                              LoginLabeledField(
                                label: 'E-Mail-Adresse bestätigen',
                                child: LoginTextField(
                                  formFieldKey: _emailFieldKey,
                                  controller: _emailController,
                                  hintText: _accountEmail ?? 'deine@email.de',
                                  keyboardType: TextInputType.emailAddress,
                                  validator: _fieldErrors.merge(
                                    _emailFieldId,
                                    (value) {
                                      final input = value?.trim().toLowerCase();
                                      final email = _accountEmail
                                          ?.trim()
                                          .toLowerCase();
                                      if (input == null || input.isEmpty) {
                                        return 'Bitte E-Mail-Adresse eingeben.';
                                      }
                                      if (email == null || input != email) {
                                        return 'E-Mail stimmt nicht mit deinem Konto überein.';
                                      }
                                      return null;
                                    },
                                  ),
                                  onChanged: (_) {
                                    _onFieldEdited(_emailFieldId);
                                    _onFormChanged();
                                  },
                                ),
                              ),
                            SizedBox(height: fieldGap),
                            LoginLabeledField(
                              label: 'Bestätigung',
                              child: LoginTextField(
                                formFieldKey: _confirmationFieldKey,
                                controller: _confirmationController,
                                hintText: '$_confirmationPhrase eingeben',
                                validator: (value) {
                                  final input = value?.trim();
                                  if (input == null || input.isEmpty) {
                                    return 'Bitte $_confirmationPhrase eingeben.';
                                  }
                                  if (input != _confirmationPhrase) {
                                    return 'Gib exakt $_confirmationPhrase ein.';
                                  }
                                  return null;
                                },
                                onChanged: (_) => _onFormChanged(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tippe „$_confirmationPhrase“, um die Löschung freizuschalten.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.45,
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
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.error,
                        foregroundColor: scheme.onError,
                        disabledBackgroundColor:
                            scheme.error.withValues(alpha: AppOpacity.disabled),
                        disabledForegroundColor: scheme.onError.withValues(
                          alpha: AppOpacity.disabled,
                        ),
                        shape: AppSquircle.shape(AppRadius.l),
                      ),
                      onPressed: _canSubmit ? _onDeletePressed : null,
                      child: _busy
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  scheme.onError,
                                ),
                              ),
                            )
                          : const Text('Konto unwiderruflich löschen'),
                    ),
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

class _DangerWarningCard extends StatelessWidget {
  const _DangerWarningCard({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.45),
        borderRadius: AppSquircle.borderRadius(AppRadius.l),
        border: Border.all(
          color: scheme.error.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PhosphorIcon(
              PhosphorIcons.warningOctagon(PhosphorIconsStyle.fill),
              size: 28,
              color: scheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gefahrenzone',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Das Löschen deines Kontos ist endgültig. Es gibt keinen '
                    'Wiederherstellungsweg — weder für dich noch für uns.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onErrorContainer.withValues(alpha: 0.92),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsequenceList extends StatelessWidget {
  const _ConsequenceList({required this.scheme});

  final ColorScheme scheme;

  static const _items = <String>[
    'Dein Profil und alle persönlichen Angaben',
    'Kalender-Einstellungen und gespeicherte Präferenzen',
    'Push-Benachrichtigungen und Geräte-Verknüpfungen',
    'Hochgeladene Dateien in deinem Konto',
    'Dein Zugang zur App — du musst dich neu registrieren',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Folgendes geht verloren:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        for (final item in _items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: PhosphorIcon(
                    PhosphorIcons.xCircle(PhosphorIconsStyle.fill),
                    size: 18,
                    color: scheme.error.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
