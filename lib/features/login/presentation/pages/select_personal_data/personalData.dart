import 'package:flutter/material.dart';

import '../../../domain/models/login_flow_step.dart';
import '../../routes/login_routes.dart';
import 'widgets/login_personal_data_fields.dart';
import '../login_step_scaffold.dart';

class PersonalDataPage extends StatefulWidget {
  const PersonalDataPage({super.key});

  @override
  State<PersonalDataPage> createState() => _PersonalDataPageState();
}

class _PersonalDataPageState extends State<PersonalDataPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  String _selectedClass = 'Klasse';

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
      child: LoginPersonalDataFields(
        firstNameController: _firstNameController,
        lastNameController: _lastNameController,
        selectedClass: _selectedClass,
        onClassChanged: (value) => setState(() => _selectedClass = value),
      ),
    );
  }
}
