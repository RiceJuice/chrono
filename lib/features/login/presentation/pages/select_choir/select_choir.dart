import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/auth_repository.dart';
import '../../../domain/models/login_flow_step.dart';
import '../../providers/auth_repository_provider.dart';
import '../../copy/login_flow_role_ui.dart';
import '../../providers/login_step_scaffold.dart';
import '../../providers/profile_gate_provider.dart';
import '../../state/login_flow_draft.dart';
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
  bool _syncedChoirFromCarousel = false;

  static const List<String> _voices = ['Tenor', 'Sopran', 'Alt', 'Bass'];
  static const List<String> _choirs = [
    'DKM',
    'Giehl',
    'Rädlinger',
    'Schola',
    'Szuczies',
  ];

  String get _choirLabelForCurrentPage =>
      _choirs[_choirPage % _choirs.length];

  @override
  void initState() {
    super.initState();
    _selectedVoice = _draft.voice;
    _choirPage = _draft.choirPage;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_syncedChoirFromCarousel) return;
    _syncedChoirFromCarousel = true;
    // Nicht synchron während des Builds: Riverpod verbietet State-Updates hier
    // (SyncProviderElement / setValueFromState).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(selectedChoirProvider.notifier).selectChoir(_choirLabelForCurrentPage);
    });
  }

  @override
  Widget build(BuildContext context) {
    final roleUi = LoginFlowRoleUi.fromStoredRoleLabel(_draft.role);
    return LoginStepScaffold(
      step: LoginFlowStep.choir,
      titleOverride: roleUi.scaffoldTitle(LoginFlowStep.choir),
      headerPadding: const EdgeInsets.symmetric(horizontal: 20),
      centerChildInScrollViewport: true,
      submitBusy: _busy,
      canProceed: () {
        final bool isVoiceSelected = _voices.contains(_selectedVoice);

        if (!isVoiceSelected) {
          showAppToast(
            context,
            'Bitte wähle eine Stimme aus.',
            kind: AppToastKind.info,
          );
          return false;
        }

        // Chor wird automatisch durch Karussell-Position gesetzt
        return true;
      },
      onAsyncProceed: (goNext) async {
        setState(() => _busy = true);
        try {
          // Immer den sichtbaren Chor mitschicken — sonst bleibt `choir` in der DB
          // leer, das Gate verlangt weiter /login/choir und /calendar wird sofort
          // wieder umgeleitet.
          final selectedChoir = ref.read(selectedChoirProvider) ??
              _choirLabelForCurrentPage;
          final saved = await ref.read(authRepositoryProvider).updateProfile(
                voice: _selectedVoice,
                choir: selectedChoir,
              );
          if (!saved) {
            throw AuthRepositoryException(
              'Profil konnte nicht gespeichert werden. Bitte erneut versuchen.',
            );
          }
          await ref.read(profileGateProvider).refresh();
          if (!context.mounted) return;
          // Nicht zu `requiredPath` navigieren: Nach dem Speichern kann die
          // Profil-Abfrage kurz hinterherhinken und noch alte/leere Werte
          // liefern → fälschlich z. B. wieder `/login/role`. Der Router leitet
          // von `/calendar` ggf. zurück auf den richtigen Schritt.
          goNext();
        } finally {
          if (context.mounted) setState(() => _busy = false);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LoginChoirSelection(
            selectedPage: _choirPage,
            selectedVoice: _selectedVoice,
            onPageChanged: (page) => setState(() {
              _choirPage = page;
              _draft.choirPage = page;
              final choirLabel = _choirs[page % _choirs.length];
              ref.read(selectedChoirProvider.notifier).selectChoir(choirLabel);
            }),
            onVoiceChanged: (voice) => setState(() {
              // Wird aktuell nicht genutzt, bleibt aber für mögliche spätere Erweiterungen konsistent.
              _selectedVoice = voice;
              _draft.voice = voice;
            }),
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
