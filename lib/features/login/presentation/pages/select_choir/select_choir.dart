import 'package:flutter/material.dart';

import '../../../domain/models/login_flow_step.dart';
import '../../routes/login_routes.dart';
import '../../state/login_flow_draft.dart';
import '../login_step_scaffold.dart';
import 'widgets/login_choir_selection.dart';

class ChoirPage extends StatefulWidget {
  const ChoirPage({super.key});

  @override
  State<ChoirPage> createState() => _ChoirPageState();
}

class _ChoirPageState extends State<ChoirPage> {
  final _draft = LoginFlowDraft.instance;
  late String _selectedVoice;
  late int _choirPage;

  @override
  void initState() {
    super.initState();
    _selectedVoice = _draft.voice;
    _choirPage = _draft.choirPage;
  }

  @override
  Widget build(BuildContext context) {
    return LoginStepScaffold(
      step: LoginFlowStep.choir,
      backPath: LoginPaths.personalData,
      child: LoginChoirSelection(
        selectedPage: _choirPage,
        selectedVoice: _selectedVoice,
        onPageChanged: (page) => setState(() {
          _choirPage = page;
          _draft.choirPage = page;
        }),
        onVoiceChanged: (voice) => setState(() {
          _selectedVoice = voice;
          _draft.voice = voice;
        }),
      ),
    );
  }
}
