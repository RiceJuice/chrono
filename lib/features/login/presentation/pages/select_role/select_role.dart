import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/auth_repository.dart';
import '../../../domain/models/login_flow_step.dart';
import '../../providers/auth_repository_provider.dart';
import '../../providers/login_step_scaffold.dart';
import '../../providers/profile_gate_provider.dart';
import '../../routes/login_routes.dart';
import '../../state/login_flow_draft.dart';
import 'widgets/login_role_selection.dart';

class SelectRolePage extends ConsumerStatefulWidget {
  const SelectRolePage({super.key});

  @override
  ConsumerState<SelectRolePage> createState() => _SelectRolePageState();
}

class _SelectRolePageState extends ConsumerState<SelectRolePage> {
  final _draft = LoginFlowDraft.instance;
  late String _selectedRole;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = _draft.role;
  }

  @override
  Widget build(BuildContext context) {
    return LoginStepScaffold(
      step: LoginFlowStep.role,
      nextPath: LoginPaths.personalData,
      submitBusy: _busy,
      contentMaxWidth: LoginStepScaffold.defaultContentMaxWidth,
      primaryButtonMaxWidth: LoginStepScaffold.defaultContentMaxWidth,
      canProceed: () {
        if (_selectedRole.trim().isEmpty) {
          showAppToast(
            context,
            'Bitte wähle eine Rolle aus.',
            kind: AppToastKind.info,
          );
          return false;
        }
        return true;
      },
      onAsyncProceed: (goNext) async {
        setState(() => _busy = true);
        try {
          await ref
              .read(authRepositoryProvider)
              .updateProfile(role: _selectedRole);
          await ref.read(profileGateProvider).refresh();
          if (!context.mounted) return;
          goNext();
        } on AuthRepositoryException {
          rethrow;
        } finally {
          if (context.mounted) setState(() => _busy = false);
        }
      },
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
