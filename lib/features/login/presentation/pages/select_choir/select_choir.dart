import 'package:flutter/material.dart';

import '../../../domain/models/login_flow_step.dart';
import '../../routes/login_routes.dart';
import '../../widgets/login_choir_selection.dart';
import '../login_step_scaffold.dart';

class ChoirPage extends StatefulWidget {
  const ChoirPage({super.key});

  @override
  State<ChoirPage> createState() => _ChoirPageState();
}

class _ChoirPageState extends State<ChoirPage> {
  String _selectedVoice = 'Tenor';
  int _choirPage = 1;

  @override
  Widget build(BuildContext context) {
    return LoginStepScaffold(
      step: LoginFlowStep.choir,
      backPath: LoginPaths.personalData,
      child: LoginChoirSelection(
        selectedPage: _choirPage,
        selectedVoice: _selectedVoice,
        onPageChanged: (page) => setState(() => _choirPage = page),
        onVoiceChanged: (voice) => setState(() => _selectedVoice = voice),
      ),
    );
  }
}
