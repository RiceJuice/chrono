import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/auth_repository.dart';
import '../../../domain/models/login_flow_step.dart';
import '../../providers/auth_repository_provider.dart';
import '../../providers/klassen_provider.dart';
import '../../copy/login_flow_role_ui.dart';
import '../../providers/login_step_scaffold.dart';
import '../../providers/profile_gate_provider.dart';
import '../../routes/login_routes.dart';
import '../../state/login_flow_draft.dart';
import '../../utils/login_form_validation.dart';
import 'widgets/forms.dart';

class PersonalDataPage extends ConsumerStatefulWidget {
  const PersonalDataPage({super.key});

  @override
  ConsumerState<PersonalDataPage> createState() => _PersonalDataPageState();
}

class _PersonalDataPageState extends ConsumerState<PersonalDataPage> {
  final _draft = LoginFlowDraft.instance;
  final _formKey = GlobalKey<FormState>();
  final _firstNameFieldKey = GlobalKey<FormFieldState<dynamic>>();
  final _lastNameFieldKey = GlobalKey<FormFieldState<dynamic>>();
  final _classFieldKey = GlobalKey<FormFieldState<dynamic>>();
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
    final classOptionsAsync = ref.watch(availableClassesProvider);
    final classOptions = classOptionsAsync.asData?.value ?? const <String>[];
    final roleUi = LoginFlowRoleUi.fromStoredRoleLabel(_draft.role);

    return LoginStepScaffold(
      step: LoginFlowStep.personalData,
      titleOverride: roleUi.scaffoldTitle(LoginFlowStep.personalData),
      nextPath: LoginPaths.choir,
      submitBusy: _busy,
      canProceed: () => loginValidateFormAndScrollToFirstError(
            context,
            formKey: _formKey,
            orderedFieldKeys: [
              _firstNameFieldKey,
              _lastNameFieldKey,
              _classFieldKey,
            ],
          ),
      onAsyncProceed: (goNext) async {
        setState(() => _busy = true);
        try {
          _draft.firstName = _firstNameController.text.trim();
          _draft.lastName = _lastNameController.text.trim();
          if (_draft.firstName.isEmpty || _draft.lastName.isEmpty) {
            if (!context.mounted) return;
            showAppToast(
              context,
              'Bitte Vorname und Nachname ausfüllen.',
              kind: AppToastKind.info,
            );
            throw const LoginStepErrorAlreadyShown();
          }
          final className = _draft.schoolClass;
          if (className == null || className.trim().isEmpty) {
            if (!context.mounted) return;
            showAppToast(
              context,
              'Bitte wähle eine Klasse aus.',
              kind: AppToastKind.info,
            );
            throw const LoginStepErrorAlreadyShown();
          }
          await ref.read(authRepositoryProvider).updateProfile(
                firstName: _draft.firstName,
                lastName: _draft.lastName,
                className: className,
              );
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
        child: Form(
          key: _formKey,
          child: LoginPersonalDataFields(
            firstNameFieldKey: _firstNameFieldKey,
            lastNameFieldKey: _lastNameFieldKey,
            classFieldKey: _classFieldKey,
            firstNameController: _firstNameController,
            lastNameController: _lastNameController,
            selectedClass: _selectedClass,
            classOptions: classOptions,
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
