import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/auth_repository.dart';
import '../../../domain/models/login_flow_step.dart';
import '../../providers/auth_repository_provider.dart';
import '../../routes/login_routes.dart';
import '../../state/login_flow_draft.dart';
import '../../providers/login_step_scaffold.dart';
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
  bool _busy = false;

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
      submitBusy: _busy,
      canProceed: () {
        final bool isVoiceSelected = _voices.contains(_selectedVoice);
        final bool isChoirSelected = ref.read(selectedChoirProvider) != null;

        if (!isVoiceSelected) {
          showAppToast(
            context,
            'Bitte wähle eine Stimme aus.',
            kind: AppToastKind.info,
          );
          return false;
        }

        if (!isChoirSelected) {
          showAppToast(
            context,
            'Bitte wähle einen Chor aus.',
            kind: AppToastKind.info,
          );
          return false;
        }

        return true;
      },
      onAsyncProceed: (goNext) async {
        setState(() => _busy = true);
        try {
          final draft = LoginFlowDraft.instance;

          final saved = await ref.read(authRepositoryProvider).updateProfile(
                firstName: draft.firstName,
                lastName: draft.lastName,
                className: draft.schoolClass,
                voice: draft.voice,
                role: draft.role,
              );
          if (!saved) {
            throw AuthRepositoryException(
              'Profil konnte nicht gespeichert werden. Bitte erneut versuchen.',
            );
          }
          if (!context.mounted) return;
          goNext();
        } on AuthRepositoryException catch (e) {
          if (!context.mounted) return;
          showAppToast(context, e.message, kind: AppToastKind.error);
        } catch (_) {
          if (!context.mounted) return;
          showAppToast(
            context,
            'Profil konnte nicht gespeichert werden. Bitte erneut versuchen.',
            kind: AppToastKind.error,
          );
        } finally {
          if (context.mounted) setState(() => _busy = false);
        }
      },
      child: Column(
        children: [
          
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
          
          Dropdown(
            selectedVoice: _selectedVoice,
            onVoiceChanged: (voice) => setState(() {
              _selectedVoice = voice;
              _draft.voice = voice;
            }),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
