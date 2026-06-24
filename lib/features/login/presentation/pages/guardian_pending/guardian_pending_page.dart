import 'dart:async';

import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/guardian_link_repository.dart';
import '../../../domain/models/guardian_child_link.dart';
import '../../../domain/models/login_flow_step.dart';
import '../../providers/guardian_link_providers.dart';
import '../../providers/profile_gate_provider.dart';
import '../../routes/login_routes.dart';
import '../../services/guardian_link_request_coordinator.dart';
import '../../state/login_flow_draft.dart';
import '../../widgets/login_step_layout.dart';
import '../../widgets/login_step_scaffold.dart';
import '../credentials/credentials_page.dart';
import '../email_confirmation/widgets/email_confirmation_ui.dart';
import 'widgets/guardian_pending_body.dart';
import 'widgets/guardian_pending_footer.dart';

class GuardianPendingPage extends ConsumerStatefulWidget {
  const GuardianPendingPage({super.key});

  @override
  ConsumerState<GuardianPendingPage> createState() =>
      _GuardianPendingPageState();
}

class _GuardianPendingPageState extends ConsumerState<GuardianPendingPage>
    with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 5);

  final _coordinator = GuardianLinkRequestCoordinator.instance;

  Timer? _pollTimer;
  bool _advancing = false;
  String? _reminderBusyLinkId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _coordinator.addListener(_onCoordinatorChanged);
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      unawaited(_runAdvanceCheck());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_runAdvanceCheck());
    });
  }

  @override
  void dispose() {
    _coordinator.removeListener(_onCoordinatorChanged);
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  void _onCoordinatorChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_runAdvanceCheck());
    }
  }

  List<GuardianChildLink> _pendingLinks(List<GuardianChildLink> links) {
    return links.where((l) => l.isPending).toList(growable: false);
  }

  List<String> _resolveChildNames(List<GuardianChildLink> pending) {
    if (pending.isNotEmpty) {
      return pending.map((l) => l.childDisplayName).toList(growable: false);
    }
    final fromDraft = LoginFlowDraft.instance.pendingChildDisplayName.trim();
    if (fromDraft.isNotEmpty) {
      return fromDraft
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return const [];
  }

  Future<void> _runAdvanceCheck() async {
    if (!mounted || _advancing) return;
    _advancing = true;
    try {
      final confirmed = await ref
          .read(guardianLinkRepositoryProvider)
          .tryApplyConfirmedLink();
      if (confirmed == null || !mounted) return;

      _coordinator.reset();
      await ref.read(profileGateProvider).refresh();
      if (!mounted) return;

      showAppToast(
        context,
        '${confirmed.childDisplayName} hat die Verknüpfung bestätigt.',
        kind: AppToastKind.success,
      );
      context.go(LoginPaths.success);
    } on GuardianLinkRepositoryException {
      if (!mounted) return;
    } catch (_) {
      if (!mounted) return;
    } finally {
      _advancing = false;
    }
  }

  Future<void> _sendReminder(GuardianChildLink link) async {
    setState(() => _reminderBusyLinkId = link.id);
    try {
      await ref.read(guardianLinkRepositoryProvider).sendReminder(link.id);
      if (!mounted) return;
      showAppToast(
        context,
        'Erinnerung wurde an ${link.childDisplayName} gesendet.',
        kind: AppToastKind.success,
      );
    } on GuardianLinkRepositoryException catch (e) {
      if (!mounted) return;
      showAppToast(context, e.message, kind: AppToastKind.error);
    } finally {
      if (mounted) setState(() => _reminderBusyLinkId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final linksAsync = ref.watch(guardianLinksProvider);
    final metrics = EmailConfirmationLayoutMetrics.fromContext(context);
    final styles = EmailConfirmationTextStyles.fromContext(context);
    final pending = linksAsync.maybeWhen(
      data: _pendingLinks,
      orElse: () => const <GuardianChildLink>[],
    );
    final childNames = _resolveChildNames(pending);

    ref.listen(guardianLinksProvider, (prev, next) {
      next.whenData((links) {
        if (links.any((l) => l.isConfirmed)) {
          unawaited(_runAdvanceCheck());
        }
      });
    });

    return LoginStepScaffold(
      step: LoginFlowStep.guardianPending,
      titleOverride: 'Bestätigung ausstehend',
      subtitleOverride: childNames.isEmpty
          ? 'Wir warten auf die Bestätigung durch deine Kinder.'
          : 'Wir warten auf die Bestätigung durch ${childNames.join(', ')}.',
      showPrimaryButton: false,
      contentMaxWidth: CredentialsPage.maxFormWidth,
      bottomBehavior: LoginBottomBehavior.footerInScroll,
      footerSpacing: LoginFooterSpacing(
        lead: metrics.footerLead,
        tail: metrics.footerTail,
      ),
      footer: GuardianPendingFooter(
        styles: styles,
        pendingLinks: pending,
        reminderBusyLinkId: _reminderBusyLinkId,
        onReminder: (link) => unawaited(_sendReminder(link)),
        onSelectOther: () => context.go(LoginPaths.selectChild),
        onAddChild: () => context.go(LoginPaths.selectChild),
      ),
      child: GuardianPendingBody(
        childNames: childNames,
        metrics: metrics,
        styles: styles,
        isSending: _coordinator.isSending,
        sendError: _coordinator.errorMessage,
      ),
    );
  }
}
