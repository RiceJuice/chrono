import 'package:flutter/material.dart';

import '../../../domain/models/login_flow_step.dart';
import '../../routes/login_routes.dart';
import '../../state/login_flow_draft.dart';
import '../login_step_scaffold.dart';
import 'widgets/login_register_fields.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _draft = LoginFlowDraft.instance;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController.text = _draft.email;
    _passwordController.text = _draft.password;
    _passwordConfirmController.text = _draft.passwordConfirm;

    _emailController.addListener(() => _draft.email = _emailController.text);
    _passwordController.addListener(
      () => _draft.password = _passwordController.text,
    );
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

  @override
  Widget build(BuildContext context) {
    return LoginStepScaffold(
      step: LoginFlowStep.register,
      backPath: LoginPaths.login,
      nextPath: LoginPaths.role,
      canProceed: () => _formKey.currentState?.validate() ?? false,
      child: Form(
        key: _formKey,
        child: LoginRegisterFields(
          emailController: _emailController,
          passwordController: _passwordController,
          passwordConfirmController: _passwordConfirmController,
        ),
      ),
    );
  }
}
