import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/auth_repository.dart';
import '../../../domain/models/login_flow_step.dart';
import '../../providers/auth_repository_provider.dart';
import '../../providers/login_step_scaffold.dart';
import '../../providers/profile_gate_provider.dart';
import '../../routes/login_routes.dart';
import '../../state/login_flow_draft.dart';
import '../../utils/login_form_validation.dart';
import 'widgets/account_auth_mode.dart';
import 'widgets/account_auth_mode_selector.dart';
import 'widgets/credential_form_fields.dart';

class CredentialsPage extends ConsumerStatefulWidget {
  const CredentialsPage({
    super.key,
    this.initialMode = AccountAuthMode.signUp,
  });

  /// Gemeinsame Maximalbreite für Formularfelder und Primärbutton (Tablet/Desktop).
  static const double maxFormWidth = 400;

  final AccountAuthMode initialMode;

  @override
  ConsumerState<CredentialsPage> createState() => _CredentialsPageState();
}

class _CredentialsPageState extends ConsumerState<CredentialsPage> {
  final _draft = LoginFlowDraft.instance;
  final _formKey = GlobalKey<FormState>();
  final _emailFieldKey = GlobalKey<FormFieldState<dynamic>>();
  final _passwordFieldKey = GlobalKey<FormFieldState<dynamic>>();
  final _passwordConfirmFieldKey = GlobalKey<FormFieldState<dynamic>>();

  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _passwordConfirmController;

  late AccountAuthMode _mode;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _emailController = TextEditingController(text: _draft.email);
    _passwordController = TextEditingController(text: _draft.password);
    _passwordConfirmController =
        TextEditingController(text: _draft.passwordConfirm);

    _emailController.addListener(() => _draft.email = _emailController.text);
    _passwordController
        .addListener(() => _draft.password = _passwordController.text);
    _passwordConfirmController.addListener(
      () => _draft.passwordConfirm = _passwordConfirmController.text,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _showError(String message) async {
    if (!mounted) return;
    showAppToast(context, message, kind: AppToastKind.error);
  }

  Future<bool> _runSignIn() async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signInWithPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      return true;
    } on AuthRepositoryException catch (e) {
      await _showError(e.message);
      return false;
    } catch (_) {
      await _showError('Anmeldung fehlgeschlagen. Bitte versuche es erneut.');
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<SignUpResult?> _runSignUp() async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      return await repo.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        firstName: '',
        lastName: '',
      );
    } on AuthRepositoryException catch (e) {
      await _showError(e.message);
      return null;
    } catch (_) {
      await _showError('Registrierung fehlgeschlagen. Bitte versuche es erneut.');
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _validateAndScrollToFirstError() => loginValidateFormAndScrollToFirstError(
        context,
        formKey: _formKey,
        orderedFieldKeys: [
          _emailFieldKey,
          _passwordFieldKey,
          if (_mode == AccountAuthMode.signUp) _passwordConfirmFieldKey,
        ],
      );

  @override
  Widget build(BuildContext context) {
    final isSignIn = _mode == AccountAuthMode.signIn;
    final double screenH = MediaQuery.sizeOf(context).height;
    final double footerLead =
        (screenH * 0.055).clamp(20.0, 52.0);
    final double footerTail =
        (screenH * 0.022).clamp(10.0, 22.0);

    return LoginStepScaffold(
      step: LoginFlowStep.credentials,
      titleOverride: isSignIn ? 'Anmelden' : 'Registrieren',
      subtitleOverride: isSignIn
          ? 'Willkommen zurück!'
          : 'Lege jetzt los und erstelle dein Konto',
      submitLabel: isSignIn ? 'Anmelden' : 'Registrieren',
      submitBusy: _busy,
      nextPath: LoginPaths.role,
      // Kein Viewport-Centering: LoginScrollSurface (SingleChildScrollView +
      // Scrollbar) darf den Inhalt natürlich wachsen lassen, wodurch Scrolling
      // und Scrollbar-Thumb korrekt funktionieren.
      centerChildInScrollViewport: false,
      contentMaxWidth: CredentialsPage.maxFormWidth,
      primaryButtonMaxWidth: CredentialsPage.maxFormWidth,
      footerLeadHeight: footerLead,
      footerTailHeight: footerTail,
      // Footer sitzt außerhalb des Scrollbereichs direkt über dem PrimaryButton:
      // Er scrollt nicht mit dem Formular mit. Beim Einblenden der Tastatur
      // wandert der Button (mit Footer als fixer Block direkt darüber) nach oben.
      footerInScrollArea: false,
      footer: AccountAuthModeSelector(
        selectedMode: _mode,
        onChanged: (mode) => setState(() => _mode = mode),
      ),
      canProceed: _validateAndScrollToFirstError,
      onAsyncProceed: (goNext) async {
        if (_mode == AccountAuthMode.signIn) {
          final success = await _runSignIn();
          if (!context.mounted) return;
          if (!success) throw const LoginStepErrorAlreadyShown();
          await ref.read(profileGateProvider).refresh();
          if (!context.mounted) return;
          final target =
              ref.read(profileGateProvider).requiredPath ?? '/calendar';
          context.go(target);
          return;
        }

        final signUpResult = await _runSignUp();
        if (!context.mounted) return;
        if (signUpResult == null) throw const LoginStepErrorAlreadyShown();
        if (signUpResult.outcome == SignUpOutcome.registeredAndSignedIn) {
          await ref.read(profileGateProvider).refresh();
          if (!context.mounted) return;
          goNext();
          return;
        }

        context.go(LoginPaths.emailConfirmation);
      },
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            CredentialFormFields(
              emailController: _emailController,
              passwordController: _passwordController,
              passwordConfirmController: _passwordConfirmController,
              requirePasswordConfirmation: _mode == AccountAuthMode.signUp,
              emailFieldKey: _emailFieldKey,
              passwordFieldKey: _passwordFieldKey,
              passwordConfirmFieldKey: _passwordConfirmFieldKey,
            ),
          ],
        ),
      ),
    );
  }
}