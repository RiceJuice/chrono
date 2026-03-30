import 'package:flutter/material.dart';

import '../../../domain/models/login_flow_step.dart';
import '../../routes/login_routes.dart';
import 'widgets/login_role_selection.dart';
import '../login_step_scaffold.dart';

class SelectRolePage extends StatefulWidget {
  const SelectRolePage({super.key});

  @override
  State<SelectRolePage> createState() => _SelectRolePageState();
}

class _SelectRolePageState extends State<SelectRolePage> {
  String _selectedRole = 'Elternteil';

  @override
  Widget build(BuildContext context) {
    return LoginStepScaffold(
      step: LoginFlowStep.role,
      backPath: LoginPaths.register,
      nextPath: LoginPaths.personalData,
      child: LoginRoleSelection(
        selectedRole: _selectedRole,
        onSelect: (role) => setState(() => _selectedRole = role),
      ),
    );
  }
}
