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
import '../../services/guardian_link_request_coordinator.dart';
import '../../state/login_flow_draft.dart';
import '../../widgets/login_step_scaffold.dart';

class SelectChildPage extends ConsumerStatefulWidget {
  const SelectChildPage({
    super.key,
    this.onLinkRequested,
    this.classNamesOverride,
  });

  /// Wenn gesetzt (z. B. aus Einstellungen), kein Onboarding-Redirect.
  final VoidCallback? onLinkRequested;

  /// Session-Klassenfilter (Einstellungen); sonst Draft.
  final List<String>? classNamesOverride;

  @override
  ConsumerState<SelectChildPage> createState() => _SelectChildPageState();
}

class _SelectChildPageState extends ConsumerState<SelectChildPage> {
  final _draft = LoginFlowDraft.instance;
  final _searchController = TextEditingController();
  List<StudentSearchResult> _results = const [];
  final Set<String> _selectedChildIds = {};
  bool _searching = false;
  bool _submitting = false;
  String _lastQuery = '';
  Timer? _searchDebounce;

  bool get _isSettingsMode => widget.onLinkRequested != null;

  List<String> get _classNames =>
      widget.classNamesOverride ?? _draft.guardianChildClasses;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  GuardianChildLink? _existingLinkFor(String childId) {
    final links = ref.read(guardianLinksProvider);
    return links.maybeWhen(
      data: (items) {
        for (final link in items) {
          if (link.childId == childId) return link;
        }
        return null;
      },
      orElse: () => null,
    );
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

    if (_classNames.isEmpty) {
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
      final results = await ref
          .read(guardianLinkRepositoryProvider)
          .searchStudents(trimmed, classNames: _classNames);
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

  void _toggleSelection(StudentSearchResult student) {
    final existing = _existingLinkFor(student.id);
    if (existing != null) return;

    setState(() {
      if (_selectedChildIds.contains(student.id)) {
        _selectedChildIds.remove(student.id);
      } else {
        _selectedChildIds.add(student.id);
      }
    });
  }

  List<String> _selectedDisplayNames() {
    return _results
        .where((s) => _selectedChildIds.contains(s.id))
        .map((s) => s.displaySubtitle)
        .toList(growable: false);
  }

  void _showRequestResultToast(RequestLinksResult result, int requestedCount) {
    if (!mounted) return;

    if (result.anyPushFailed) {
      showAppToast(
        context,
        'Anfragen gespeichert. Push konnte nicht an alle Kinder zugestellt werden.',
        kind: AppToastKind.info,
      );
      return;
    }

    final createdCount = result.createdLinks.length;
    showAppToast(
      context,
      createdCount <= 1
          ? 'Anfrage wurde gesendet.'
          : '$createdCount Anfragen wurden gesendet.',
      kind: AppToastKind.success,
    );
  }

  Future<void> _sendRequestsInBackground(List<String> childIds) async {
    final coordinator = GuardianLinkRequestCoordinator.instance;
    coordinator.markSending();
    try {
      final result = await ref
          .read(guardianLinkRepositoryProvider)
          .requestLinks(childIds);
      await ref.read(profileGateProvider).refresh();
      coordinator.markDone();
      if (!result.hasCreatedLinks && childIds.isNotEmpty) {
        coordinator.markFailed(
          'Für die ausgewählten Kinder liegen bereits Anfragen vor.',
        );
      }
    } on GuardianLinkRepositoryException catch (e) {
      coordinator.markFailed(e.message);
    } catch (_) {
      coordinator.markFailed(
        'Verknüpfungsanfragen konnten nicht gesendet werden.',
      );
    }
  }

  Future<void> _submitRequests(void Function() goNext) async {
    if (_selectedChildIds.isEmpty) return;

    final names = _selectedDisplayNames();
    _draft.pendingChildDisplayName = names.join(', ');
    final childIds = _selectedChildIds.toList(growable: false);

    if (_isSettingsMode) {
      setState(() => _submitting = true);
      try {
        final result = await ref
            .read(guardianLinkRepositoryProvider)
            .requestLinks(childIds);
        await ref.read(profileGateProvider).refresh();
        if (!mounted) return;
        widget.onLinkRequested!();
        _showRequestResultToast(result, childIds.length);
        Navigator.of(context).pop();
      } on GuardianLinkRepositoryException catch (e) {
        if (!mounted) return;
        showAppToast(context, e.message, kind: AppToastKind.error);
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
      return;
    }

    GuardianLinkRequestCoordinator.instance.markSending();
    if (!mounted) return;
    context.go(LoginPaths.guardianPending);
    unawaited(_sendRequestsInBackground(childIds));
  }

  @override
  Widget build(BuildContext context) {
    final roleUi = LoginFlowRoleUi.fromStoredRoleLabel(_draft.role);
    final theme = Theme.of(context);

    return LoginStepScaffold(
      step: LoginFlowStep.selectChild,
      titleOverride: roleUi.scaffoldTitle(LoginFlowStep.selectChild),
      subtitleOverride: _isSettingsMode
          ? 'Wähle ein oder mehrere Kinder aus der Liste. Du kannst jederzeit '
              'weitere Kinder hinzufügen.'
          : 'Wähle ein oder mehrere Kinder aus der Liste und sende die '
              'Verknüpfungsanfragen.',
      showPrimaryButton: true,
      submitLabel: 'Anfragen senden',
      submitBusy: _submitting,
      contentMaxWidth: LoginStepScaffold.defaultContentMaxWidth,
      primaryButtonMaxWidth: LoginStepScaffold.defaultContentMaxWidth,
      validateBeforeProceed: () {
        if (_classNames.isEmpty) {
          showAppToast(
            context,
            'Bitte wähle zuerst mindestens eine Klasse aus.',
            kind: AppToastKind.info,
          );
          return false;
        }
        if (_selectedChildIds.isEmpty) {
          showAppToast(
            context,
            'Bitte wähle mindestens ein Kind aus.',
            kind: AppToastKind.info,
          );
          return false;
        }
        return true;
      },
      onAsyncProceed: (goNext) async => _submitRequests(goNext),
      child: Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ClassFilterBanner(
              classNames: _classNames,
              showChangeLink: !_isSettingsMode,
              onChangeClasses: !_isSettingsMode
                  ? () => context.go(LoginPaths.personalData)
                  : null,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              enabled: !_submitting && _classNames.isNotEmpty,
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
            const SizedBox(height: 12),
            if (_classNames.isEmpty)
              Text(
                'Keine Klassen ausgewählt. Bitte zuerst die Klassen deiner '
                'Kinder festlegen.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error.withValues(alpha: 0.85),
                ),
              ),
            if (_lastQuery.length >= 2 &&
                !_searching &&
                _results.isEmpty &&
                _classNames.isNotEmpty)
              Text(
                'Niemand mit diesem Namen in den gewählten Klassen gefunden.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ..._results.map((student) {
              final existing = _existingLinkFor(student.id);
              final isSelected = _selectedChildIds.contains(student.id);
              final isLinked = existing != null;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
                      : theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _submitting || isLinked
                        ? null
                        : () => _toggleSelection(student),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          if (!isLinked)
                            Checkbox(
                              value: isSelected,
                              onChanged: _submitting
                                  ? null
                                  : (_) => _toggleSelection(student),
                            )
                          else
                            const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student.displaySubtitle,
                                  style: theme.textTheme.bodyLarge,
                                ),
                                if (isLinked)
                                  Text(
                                    existing.isConfirmed
                                        ? 'Bereits verknüpft'
                                        : existing.isPending
                                            ? 'Anfrage ausstehend'
                                            : 'Abgelehnt',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ClassFilterBanner extends StatelessWidget {
  const _ClassFilterBanner({
    required this.classNames,
    required this.showChangeLink,
    this.onChangeClasses,
  });

  final List<String> classNames;
  final bool showChangeLink;
  final VoidCallback? onChangeClasses;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suche in Klassen',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            classNames.isEmpty
                ? 'Noch keine Klassen gewählt'
                : classNames.join(', '),
            style: theme.textTheme.bodyMedium,
          ),
          if (showChangeLink && onChangeClasses != null) ...[
            const SizedBox(height: 4),
            TextButton(
              onPressed: onChangeClasses,
              child: const Text('Klassen ändern'),
            ),
          ],
        ],
      ),
    );
  }
}
