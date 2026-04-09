import 'package:flutter/material.dart';

import '../../../domain/models/login_flow_step.dart';
import '../../routes/login_routes.dart';
import '../../state/login_flow_draft.dart';
import '../../providers/login_step_scaffold.dart';
import 'widgets/login_role_selection.dart';

class SelectRolePage extends StatefulWidget {
  const SelectRolePage({super.key});

  @override
  State<SelectRolePage> createState() => _SelectRolePageState();
}

class _SelectRolePageState extends State<SelectRolePage> {
  final _draft = LoginFlowDraft.instance;
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = _draft.role;
  }

  @override
  Widget build(BuildContext context) {
    return LoginStepScaffold(
      step: LoginFlowStep.role,
      backPath: LoginPaths.credentials,
      nextPath: LoginPaths.personalData,
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: LoginRoleSelection(
          selectedRole: _selectedRole,
          onSelect: (role) => setState(() {
            _selectedRole = role;
            _draft.role = role;
          }),
        ),
      ),
    );
  }
}
