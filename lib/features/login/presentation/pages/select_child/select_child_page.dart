import 'dart:async';

import 'package:chronoapp/core/auth/auth_user_id_provider.dart';
import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/guardian_link_repository.dart';
import '../../../domain/guardian_active_child_picker.dart';
import '../../../domain/guardian_link_status.dart';
import '../../../domain/models/guardian_child_link.dart';
import '../../../domain/models/login_flow_step.dart';
import '../../copy/login_flow_role_ui.dart';
import '../../providers/guardian_link_providers.dart';
import '../../providers/profile_gate_provider.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_active_child_switch.dart';
import '../../routes/login_routes.dart';
import '../../state/login_flow_draft.dart';
import '../../widgets/login_step_scaffold.dart';
import '../guardian_pending/guardian_pending_status_list.dart';
import 'package:chronoapp/core/widgets/animated_circle_checkbox.dart';

class SelectChildPage extends ConsumerStatefulWidget {
  const SelectChildPage({
    super.key,
    this.embeddedInSettings = false,
    this.onLinkRequested,
  });

  /// Eingebettet in Einstellungen (Sheet) — kein Onboarding-Redirect.
  final bool embeddedInSettings;

  /// Optionaler Callback nach erfolgreicher Anfrage (z. B. Sheet schließen).
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
  bool _proceeding = false;
  bool _confirmationListenerInitialized = false;
  final Set<String> _notifiedConfirmedChildIds = {};
  String? _reminderBusyLinkId;
  String _lastQuery = '';
  Timer? _searchDebounce;


  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<GuardianChildLink> _ownLinks(
    List<GuardianChildLink> links,
    String? userId,
  ) {
    if (userId == null) return const [];
    return links.where((l) => l.guardianId == userId).toList(growable: false);
  }

  void _notifyNewConfirmations(List<GuardianChildLink> ownLinks) {
    if (!mounted) return;

    for (final link in ownLinks) {
      if (!link.isConfirmed ||
          _notifiedConfirmedChildIds.contains(link.childId)) {
        continue;
      }
      _notifiedConfirmedChildIds.add(link.childId);
      showAppToast(
        context,
        '${link.childDisplayName} hat die Verknüpfung bestätigt.',
        kind: AppToastKind.success,
      );
    }
  }

  Future<void> _sendReminder(GuardianChildLink link) async {
    setState(() => _reminderBusyLinkId = link.id);
    try {
      await ref.read(guardianLinkRepositoryProvider).sendReminder(link.id);
      if (!mounted) return;
      showAppToast(
        context,
        'Erinnerung an ${link.childDisplayName} wurde gesendet.',
        kind: AppToastKind.success,
      );
    } on GuardianLinkRepositoryException catch (e) {
      if (!mounted) return;
      showAppToast(context, e.message, kind: AppToastKind.error);
    } finally {
      if (mounted) setState(() => _reminderBusyLinkId = null);
    }
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

  Future<void> _requestAll() async {
    if (_selected.isEmpty) return;

    final count = _selected.length;
    final result = await ref
        .read(guardianLinkRepositoryProvider)
        .requestLinks(_selected.keys.toList(growable: false));
    await ref.read(profileGateProvider).refresh();
    if (!mounted) return;

    setState(() {
      _selected.clear();
      _results = const [];
      _searchController.clear();
      _lastQuery = '';
    });

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

    if (widget.embeddedInSettings) {
      widget.onLinkRequested?.call();
      Navigator.of(context).pop();
      return;
    }

    context.go(LoginPaths.guardianPending);
  }

  Future<void> _proceedToSuccess(List<GuardianChildLink> ownLinks) async {
    final router = GoRouter.of(context);
    final confirmed =
        ownLinks.where((l) => l.isConfirmed).toList(growable: false);
    if (confirmed.isEmpty) {
      if (!context.mounted) return;
      showAppToast(
        context,
        'Noch keine Bestätigung eingegangen. Bitte kurz warten.',
        kind: AppToastKind.info,
      );
      throw const LoginStepProceedBlocked();
    }

    final activeChild = pickGuardianActiveChild(confirmed);
    await activateGuardianChildAndSyncFilters(ref, activeChild: activeChild);
    if (!mounted) return;
    router.go(LoginPaths.success);
  }

  static const Color _infoTextColor = Color(0xFFCBBBA0);

  Widget _buildInfoText(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline_rounded,
          size: 20,
          color: _infoTextColor,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Du kannst mehrere Kinder auswählen. Jedes Kind '
            'bestätigt die Anfrage einzeln in der App.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _infoTextColor,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleUi = LoginFlowRoleUi.fromStoredRoleLabel(_draft.role);
    final theme = Theme.of(context);
    final selectedCount = _selected.length;
    final isSettingsFlow = widget.embeddedInSettings;

    final linksAsync = ref.watch(guardianLinksProvider);
    final userId = ref.watch(authUserIdProvider).value;

    if (!isSettingsFlow) {
      ref.listen(guardianLinksProvider, (prev, next) {
        next.whenData((links) {
          final ownLinks = _ownLinks(links, userId);
          if (!_confirmationListenerInitialized) {
            _confirmationListenerInitialized = true;
            for (final link in ownLinks) {
              if (link.isConfirmed) {
                _notifiedConfirmedChildIds.add(link.childId);
              }
            }
            return;
          }
          _notifyNewConfirmations(ownLinks);
        });
      });
    }

    final ownLinks = linksAsync.maybeWhen(
      data: (links) => _ownLinks(links, userId),
      orElse: () => const <GuardianChildLink>[],
    );
    final hasConfirmed = guardianLinksHaveConfirmed(ownLinks);
    final hasPending = ownLinks.any((l) => l.isPending);
    final isWaiting = ownLinks.isNotEmpty && hasPending && !hasConfirmed;
    final canProceed = hasConfirmed;
    final showSendButton = selectedCount > 0 && !canProceed;

    return LoginStepScaffold(
      step: LoginFlowStep.selectChild,
      titleOverride: roleUi.scaffoldTitle(LoginFlowStep.selectChild),
      subtitleOverride: canProceed
          ? 'Mindestens ein Kind hat bestätigt. Du kannst fortfahren.'
          : isWaiting
              ? 'Wir warten auf die Bestätigung durch dein Kind.'
              : 'Suche deine Kinder und wähle alle aus, die du verknüpfen möchtest.',
      showPrimaryButton: canProceed || showSendButton,
      submitLabel: canProceed
          ? 'Weiter'
          : selectedCount == 1
              ? 'Anfrage senden'
              : 'Anfragen senden ($selectedCount)',
      submitBusy: _submitting || _proceeding,
      contentMaxWidth: LoginStepScaffold.defaultContentMaxWidth,
      primaryButtonMaxWidth: LoginStepScaffold.defaultContentMaxWidth,
      onAsyncProceed: (_) async {
        if (canProceed) {
          setState(() => _proceeding = true);
          try {
            await _proceedToSuccess(ownLinks);
          } on GuardianLinkRepositoryException catch (e) {
            if (!context.mounted) return;
            showAppToast(context, e.message, kind: AppToastKind.error);
            throw const LoginStepErrorAlreadyShown();
          } finally {
            if (mounted) setState(() => _proceeding = false);
          }
          return;
        }

        setState(() => _submitting = true);
        try {
          await _requestAll();
        } on GuardianLinkRepositoryException catch (e) {
          if (!context.mounted) return;
          showAppToast(context, e.message, kind: AppToastKind.error);
          throw const LoginStepErrorAlreadyShown();
        } finally {
          if (mounted) setState(() => _submitting = false);
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              enabled: !_submitting && !_proceeding,
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
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._results.map(
                (student) {
                  final isSelected = _selected.containsKey(student.id);
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _submitting || _proceeding
                          ? null
                          : () => _toggleStudent(student),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            AnimatedCircleCheckbox(
                              selected: isSelected,
                              enabled: !_submitting && !_proceeding,
                              onChanged: _submitting || _proceeding
                                  ? null
                                  : (_) => _toggleStudent(student),
                            ),
                            const SizedBox(width: 12),
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
                  );
                },
              ),
            ],
            if (_lastQuery.length >= 2 && !_searching && _results.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Niemand mit diesem Profilnamen gefunden. '
                'Bitte den Namen prüfen, den dein Kind in der App hinterlegt hat.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
            if (_selected.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selected.values.map((student) {
                  return InputChip(
                    label: Text(student.displaySubtitle),
                    onDeleted: _submitting || _proceeding
                        ? null
                        : () => _toggleStudent(student),
                    deleteIcon: const Icon(Icons.close, size: 18),
                  );
                }).toList(growable: false),
              ),
            ],
            if (!isSettingsFlow && ownLinks.isNotEmpty) ...[
              const SizedBox(height: 20),
              GuardianPendingStatusList(
                links: ownLinks,
                reminderBusyLinkId: _reminderBusyLinkId,
                onSendReminder: _sendReminder,
              ),
            ],
            const SizedBox(height: 20),
            _buildInfoText(theme),
          ],
        ),
      ),
    );
  }
}
