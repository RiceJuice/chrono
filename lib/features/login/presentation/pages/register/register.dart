import 'package:flutter/material.dart';

import '../../../domain/models/login_flow_step.dart';
import '../../routes/login_routes.dart';
import 'widgets/login_register_fields.dart';
import '../login_step_scaffold.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

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
      nextPath: LoginPaths.role,
      child: LoginRegisterFields(
        emailController: _emailController,
        passwordController: _passwordController,
        passwordConfirmController: _passwordConfirmController,
      ),
    );
  }
}
