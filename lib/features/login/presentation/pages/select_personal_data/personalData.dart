import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/login_flow_step.dart';
import '../../routes/login_routes.dart';
import '../../state/login_flow_draft.dart';
import '../../providers/login_step_scaffold.dart';
import '../../providers/klassen_provider.dart';
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
    final classOptionsAsync = ref.watch(availableClassesProvider);
    final classOptions = classOptionsAsync.asData?.value ?? const <String>[];

    return LoginStepScaffold(
      step: LoginFlowStep.personalData,
      backPath: LoginPaths.role,
      nextPath: LoginPaths.choir,
      submitBusy: _busy,
      canProceed: () => _formKey.currentState?.validate() ?? false,
      onAsyncProceed: (goNext) async {
        setState(() => _busy = true);
        try {
          _draft.firstName = _firstNameController.text.trim();
          _draft.lastName = _lastNameController.text.trim();
          if (!context.mounted) return;
          if (_draft.firstName.isEmpty || _draft.lastName.isEmpty) {
            showAppToast(
              context,
              'Bitte Vorname und Nachname ausfüllen.',
              kind: AppToastKind.info,
            );
            return;
          }
          goNext();
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
