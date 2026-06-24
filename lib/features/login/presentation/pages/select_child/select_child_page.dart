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
  final Map<String, StudentSearchResult> _selected = {};
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

  void _toggleStudent(StudentSearchResult student) {
    setState(() {
      if (_selected.containsKey(student.id)) {
        _selected.remove(student.id);
      } else {
        _selected[student.id] = student;
      }
    });
  }

  Future<void> _confirmAndRequestAll() async {
    if (_selected.isEmpty) return;

    final count = _selected.length;
    final names = _selected.values.map((s) => s.displayName).join(', ');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(count == 1 ? 'Kind verknüpfen' : '$count Kinder verknüpfen'),
        content: Text(
          count == 1
              ? 'Möchtest du eine Verknüpfungsanfrage an $names senden? '
                  'Das Kind muss die Anfrage in der App bestätigen.'
              : 'Möchtest du Verknüpfungsanfragen an folgende Kinder senden?\n\n'
                  '$names\n\n'
                  'Jedes Kind muss die Anfrage einzeln in der App bestätigen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(count == 1 ? 'Anfrage senden' : 'Anfragen senden'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(guardianLinkRepositoryProvider)
          .requestLinks(_selected.keys.toList(growable: false));
      await ref.read(profileGateProvider).refresh();
      if (!mounted) return;

      if (result.anyPushFailed) {
        showAppToast(
          context,
          'Anfragen gespeichert. Push konnte nicht an alle Kinder zugestellt werden.',
          kind: AppToastKind.info,
        );
      } else {
        showAppToast(
          context,
          count == 1
              ? 'Anfrage gesendet. Wir warten auf die Bestätigung.'
              : '$count Anfragen gesendet. Wir warten auf die Bestätigungen.',
          kind: AppToastKind.success,
        );
      }

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
    final selectedCount = _selected.length;

    return LoginStepScaffold(
      step: LoginFlowStep.selectChild,
      titleOverride: roleUi.scaffoldTitle(LoginFlowStep.selectChild),
      subtitleOverride:
          'Suche deine Kinder und wähle alle aus, die du verknüpfen möchtest.',
      showPrimaryButton: false,
      footer: selectedCount > 0
          ? Padding(
              padding: const EdgeInsets.only(top: 16),
              child: FilledButton(
                onPressed: _submitting ? null : _confirmAndRequestAll,
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        selectedCount == 1
                            ? 'Anfrage senden'
                            : 'Anfragen senden ($selectedCount)',
                      ),
              ),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Du kannst mehrere Kinder auswählen. Jedes Kind '
                      'bestätigt die Anfrage einzeln in der App.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_selected.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Ausgewählt',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selected.values.map((student) {
                  return InputChip(
                    label: Text(student.displaySubtitle),
                    onDeleted: _submitting
                        ? null
                        : () => _toggleStudent(student),
                    deleteIcon: const Icon(Icons.close, size: 18),
                  );
                }).toList(growable: false),
              ),
            ],
            const SizedBox(height: 20),
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
              (student) {
                final isSelected = _selected.containsKey(student.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.45)
                        : theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _submitting ? null : () => _toggleStudent(student),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isSelected,
                              onChanged: _submitting
                                  ? null
                                  : (_) => _toggleStudent(student),
                            ),
                            Expanded(
                              child: Text(
                                student.displaySubtitle,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
