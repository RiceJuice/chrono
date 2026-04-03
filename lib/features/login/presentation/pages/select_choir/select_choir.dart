import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/login_flow_step.dart';
import '../../routes/login_routes.dart';
import '../../state/login_flow_draft.dart';
import '../login_step_scaffold.dart';
import 'provider/select_choir_provider.dart';
import 'widgets/dropdown.dart';
import 'widgets/login_choir_selection.dart';

class ChoirPage extends ConsumerStatefulWidget {
  const ChoirPage({super.key});

  @override
  ConsumerState<ChoirPage> createState() => _ChoirPageState();
}

class _ChoirPageState extends ConsumerState<ChoirPage> {
  final _draft = LoginFlowDraft.instance;
  late String _selectedVoice;
  late int _choirPage;

  static const List<String> _voices = ['Tenor', 'Sopran', 'Alt', 'Bass'];
  static const List<String> _choirs = ['Giehl', 'DKM', 'Rädlinger', 'Szucies', 'Schola'];

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
      canProceed: () {
        final bool isVoiceSelected = _voices.contains(_selectedVoice);
        final bool isChoirSelected = ref.read(selectedChoirProvider) != null;

        if (!isVoiceSelected) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bitte wähle eine Stimme aus.')),
          );
          return false;
        }

        if (!isChoirSelected) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bitte wähle einen Chor aus.')),
          );
          return false;
        }

        return true;
      },
      child: Column(
        children: [
          Dropdown(
            selectedVoice: _selectedVoice,
            onVoiceChanged: (voice) => setState(() {
              _selectedVoice = voice;
              _draft.voice = voice;
            }),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LoginChoirSelection(
              selectedPage: _choirPage,
              selectedVoice: _selectedVoice,
              onPageChanged: (page) => setState(() {
                _choirPage = page;
                _draft.choirPage = page;

                // Damit "Chor ausgewählt" auch wirklich dem UI-Selection-Stand entspricht,
                // synchronisieren wir den Provider bei Page-Changes.
                final choirLabel = _choirs[page % _choirs.length];
                ref.read(selectedChoirProvider.notifier).selectChoir(choirLabel);
              }),
              onVoiceChanged: (voice) => setState(() {
                // Wird aktuell nicht genutzt, bleibt aber für mögliche spätere Erweiterungen konsistent.
                _selectedVoice = voice;
                _draft.voice = voice;
              }),
            ),
          ),
        ],
      ),
    );
  }
}
