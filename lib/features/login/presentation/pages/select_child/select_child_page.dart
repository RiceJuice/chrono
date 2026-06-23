import 'dart:async';

import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/guardian_link_repository.dart';
import '../../../domain/models/guardian_child_link.dart';
import '../../../domain/models/login_flow_step.dart';
import '../../copy/login_flow_role_ui.dart';
import '../../providers/guardian_link_providers.dart';
import '../../providers/profile_gate_provider.dart';
import '../../routes/login_routes.dart';
import '../../state/login_flow_draft.dart';
import '../../widgets/login_step_scaffold.dart';

class SelectChildPage extends ConsumerStatefulWidget {
  const SelectChildPage({super.key, this.onLinkRequested});

  /// Wenn gesetzt (z. B. aus Einstellungen), kein Onboarding-Redirect.
  final VoidCallback? onLinkRequested;

  @override
  ConsumerState<SelectChildPage> createState() => _SelectChildPageState();
}

class _SelectChildPageState extends ConsumerState<SelectChildPage> {
  final _draft = LoginFlowDraft.instance;
  final _searchController = TextEditingController();
  List<StudentSearchResult> _results = const [];
  bool _searching = false;
  bool _submitting = false;
  String _lastQuery = '';
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      setState(() {
        _results = const [];
        _searching = false;
        _lastQuery = trimmed;
      });
      return;
    }

    setState(() {
      _searching = true;
      _lastQuery = trimmed;
    });

    try {
      final results =
          await ref.read(guardianLinkRepositoryProvider).searchStudents(trimmed);
      if (!mounted || _searchController.text.trim() != trimmed) return;
      setState(() {
        _results = results;
        _searching = false;
      });
    } on GuardianLinkRepositoryException catch (e) {
      if (!mounted) return;
      setState(() => _searching = false);
      showAppToast(context, e.message, kind: AppToastKind.error);
    }
  }

  Future<void> _confirmAndRequest(StudentSearchResult student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kind verknüpfen'),
        content: Text(
          'Möchtest du eine Verknüpfungsanfrage an ${student.displaySubtitle} senden? '
          'Das Kind muss die Anfrage in der App bestätigen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Anfrage senden'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      await ref.read(guardianLinkRepositoryProvider).requestLink(student.id);
      await ref.read(profileGateProvider).refresh();
      if (!mounted) return;
      showAppToast(
        context,
        'Anfrage gesendet. Wir warten auf die Bestätigung.',
        kind: AppToastKind.success,
      );
      if (widget.onLinkRequested != null) {
        widget.onLinkRequested!();
        Navigator.of(context).pop();
        return;
      }
      context.go(LoginPaths.guardianPending);
    } on GuardianLinkRepositoryException catch (e) {
      if (!mounted) return;
      showAppToast(context, e.message, kind: AppToastKind.error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleUi = LoginFlowRoleUi.fromStoredRoleLabel(_draft.role);
    final theme = Theme.of(context);

    return LoginStepScaffold(
      step: LoginFlowStep.selectChild,
      titleOverride: roleUi.scaffoldTitle(LoginFlowStep.selectChild),
      subtitleOverride:
          'Suche den Profilnamen deines Kindes (Vor- und Nachname aus der App).',
      showPrimaryButton: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              enabled: !_submitting,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'z. B. Vorname, Nachname oder beides',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              onChanged: (value) {
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 300), () {
                  if (!mounted) return;
                  unawaited(_runSearch(_searchController.text));
                });
              },
              onSubmitted: _runSearch,
            ),
            const SizedBox(height: 16),
            if (_lastQuery.length >= 2 && !_searching && _results.isEmpty)
              Text(
                'Niemand mit diesem Profilnamen gefunden. '
                'Bitte den Namen prüfen, den dein Kind in der App hinterlegt hat.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ..._results.map(
              (student) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _submitting
                        ? null
                        : () => unawaited(_confirmAndRequest(student)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              student.displaySubtitle,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
