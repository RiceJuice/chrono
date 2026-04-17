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
import 'widgets/account_auth_mode.dart';
import 'widgets/account_auth_mode_selector.dart';
import 'widgets/credential_form_fields.dart';

class CredentialsPage extends ConsumerStatefulWidget {
  const CredentialsPage({
    super.key,
    this.initialMode = AccountAuthMode.signUp,
  });

  final AccountAuthMode initialMode;

  @override
  ConsumerState<CredentialsPage> createState() => _CredentialsPageState();
}

class _CredentialsPageState extends ConsumerState<CredentialsPage> {
  final _draft = LoginFlowDraft.instance;
  final _formKey = GlobalKey<FormState>();
  final _emailFieldKey = GlobalKey<FormFieldState<String>>();
  final _passwordFieldKey = GlobalKey<FormFieldState<String>>();
  final _passwordConfirmFieldKey = GlobalKey<FormFieldState<String>>();

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

  bool _validateAndScrollToFirstError() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (isValid) return true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final keys = <GlobalKey<FormFieldState<String>>>[
        _emailFieldKey,
        _passwordFieldKey,
        if (_mode == AccountAuthMode.signUp) _passwordConfirmFieldKey,
      ];

      for (final key in keys) {
        if (!(key.currentState?.hasError ?? false)) continue;
        final targetContext = key.currentContext;
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

  @override
  Widget build(BuildContext context) {
    final isSignIn = _mode == AccountAuthMode.signIn;

    return LoginStepScaffold(
      step: LoginFlowStep.credentials,
      titleOverride: isSignIn ? 'Anmelden' : 'Registrieren',
      subtitleOverride: isSignIn
          ? 'Willkommen zurück!'
          : 'Lege jetzt los und erstelle dein Konto',
      submitLabel: isSignIn ? 'Anmelden' : 'Registrieren',
      submitBusy: _busy,
      nextPath: LoginPaths.role,
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