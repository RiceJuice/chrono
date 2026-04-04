import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/auth_repository.dart';
import '../../../domain/models/login_flow_step.dart';
import '../../providers/auth_repository_provider.dart';
import '../../routes/login_routes.dart';
import '../../state/login_flow_draft.dart';
import '../login_step_scaffold.dart';
import 'widgets/forms.dart';

class PersonalDataPage extends ConsumerStatefulWidget {
  const PersonalDataPage({super.key});

  @override
  ConsumerState<PersonalDataPage> createState() => _PersonalDataPageState();
}

class _PersonalDataPageState extends ConsumerState<PersonalDataPage> {
  final _draft = LoginFlowDraft.instance;
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  String? _selectedClass;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _firstNameController.text = _draft.firstName;
    _lastNameController.text = _draft.lastName;
    _selectedClass = _draft.schoolClass;

    _firstNameController.addListener(
      () => _draft.firstName = _firstNameController.text,
    );
    _lastNameController.addListener(() => _draft.lastName = _lastNameController.text);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoginStepScaffold(
      step: LoginFlowStep.personalData,
      backPath: LoginPaths.role,
      nextPath: LoginPaths.choir,
      submitBusy: _busy,
      canProceed: () => _formKey.currentState?.validate() ?? false,
      onAsyncProceed: (goNext) async {
        setState(() => _busy = true);
        try {
          final draft = LoginFlowDraft.instance;
          await ref.read(authRepositoryProvider).signUp(
                email: draft.email,
                password: draft.password,
                firstName: _firstNameController.text,
                lastName: _lastNameController.text,
              );
          if (!context.mounted) return;

          if (Supabase.instance.client.auth.currentSession == null) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Konto angelegt. Bitte bestätige deine E-Mail, falls dein Projekt das vorsieht. Danach kannst du dich unter „Anmelden“ einloggen.',
                ),
              ),
            );
            context.go(LoginPaths.login);
            return;
          }

          if (!context.mounted) return;
          goNext();
        } on AuthRepositoryException catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
        } finally {
          if (context.mounted) setState(() => _busy = false);
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Form(
          key: _formKey,
          child: LoginPersonalDataFields(
            firstNameController: _firstNameController,
            lastNameController: _lastNameController,
            selectedClass: _selectedClass,
            onClassChanged: (value) => setState(() {
              _selectedClass = value;
              _draft.schoolClass = value;
            }),
          ),
        ),
      ),
    );
  }
}
