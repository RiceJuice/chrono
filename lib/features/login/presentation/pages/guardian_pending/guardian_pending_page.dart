import 'dart:async';

import 'package:chronoapp/core/auth/auth_user_id_provider.dart';
import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/guardian_link_repository.dart';
import '../../../domain/guardian_active_child_picker.dart';
import '../../../domain/models/guardian_child_link.dart';
import '../../../domain/models/login_flow_step.dart';
import '../../providers/guardian_link_providers.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_active_child_switch.dart';
import '../../routes/login_routes.dart';
import '../../widgets/login_step_scaffold.dart';
import 'guardian_pending_status_list.dart';

class GuardianPendingPage extends ConsumerStatefulWidget {
  const GuardianPendingPage({super.key});

  @override
  ConsumerState<GuardianPendingPage> createState() =>
      _GuardianPendingPageState();
}

class _GuardianPendingPageState extends ConsumerState<GuardianPendingPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  String? _reminderBusyLinkId;
  bool _proceeding = false;
  bool _confirmationListenerInitialized = false;
  bool _refreshingLinks = false;
  final Set<String> _notifiedConfirmedChildIds = {};
  List<GuardianChildLink> _remoteLinks = const [];
  Timer? _pollTimer;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.45, end: 1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => unawaited(_refreshLinksFromRemote()),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refreshLinksFromRemote());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshLinksFromRemote());
    }
  }

  List<GuardianChildLink> _ownLinks(
    List<GuardianChildLink> links,
    String? userId,
  ) {
    if (userId == null) return const [];
    return links.where((l) => l.guardianId == userId).toList(growable: false);
  }

  GuardianChildLink _mergeLink(
    GuardianChildLink? local,
    GuardianChildLink remote,
  ) {
    if (local == null) return remote;
    return GuardianChildLink(
      id: remote.id,
      guardianId: remote.guardianId,
      childId: remote.childId,
      status: remote.status,
      createdAt: remote.createdAt ?? local.createdAt,
      respondedAt: remote.respondedAt ?? local.respondedAt,
      reminderSentAt: remote.reminderSentAt ?? local.reminderSentAt,
      childFirstName: local.childFirstName,
      childLastName: local.childLastName,
      childClassName: local.childClassName,
      guardianFirstName: local.guardianFirstName,
      guardianLastName: local.guardianLastName,
    );
  }

  List<GuardianChildLink> _effectiveLinks(
    List<GuardianChildLink> streamLinks,
    String? userId,
  ) {
    final ownStreamLinks = _ownLinks(streamLinks, userId);
    if (_remoteLinks.isEmpty) return ownStreamLinks;

    final ownRemoteLinks = _ownLinks(_remoteLinks, userId);
    final streamById = {
      for (final link in ownStreamLinks) link.id: link,
    };
    final mergedIds = <String>{};
    final merged = <GuardianChildLink>[];

    for (final remote in ownRemoteLinks) {
      mergedIds.add(remote.id);
      merged.add(_mergeLink(streamById[remote.id], remote));
    }
    for (final local in ownStreamLinks) {
      if (!mergedIds.contains(local.id)) {
        merged.add(local);
      }
    }

    merged.sort(
      (a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
    );
    return merged;
  }

  bool _allRejected(List<GuardianChildLink> ownLinks) {
    if (ownLinks.isEmpty) return false;
    return ownLinks.every((l) => l.isRejected);
  }

  bool _hasPending(List<GuardianChildLink> ownLinks) {
    return ownLinks.any((l) => l.isPending);
  }

  Future<void> _refreshLinksFromRemote() async {
    if (_refreshingLinks) return;
    final userId = ref.read(authUserIdProvider).value;
    if (userId == null) return;

    _refreshingLinks = true;
    try {
      final links = await ref
          .read(guardianLinkRepositoryProvider)
          .loadLinksRemote(userId);
      if (!mounted) return;

      final ownLinks = _ownLinks(links, userId);
      setState(() => _remoteLinks = links);

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
    } catch (_) {
      // Lokaler Stream bleibt Fallback.
    } finally {
      _refreshingLinks = false;
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

  void _notifyNewConfirmations(List<GuardianChildLink> ownLinks) {
    if (!mounted) return;

    for (final link in ownLinks) {
      if (!link.isConfirmed || _notifiedConfirmedChildIds.contains(link.childId)) {
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

  Future<void> _proceedToSuccess(List<GuardianChildLink> ownLinks) async {
    final router = GoRouter.of(context);
    await _refreshLinksFromRemote();
    if (!mounted) return;

    final userId = ref.read(authUserIdProvider).value;
    final linksAsync = ref.read(guardianLinksProvider);
    final streamLinks = linksAsync.maybeWhen(
      data: (links) => links,
      orElse: () => const <GuardianChildLink>[],
    );
    final effectiveLinks = _effectiveLinks(streamLinks, userId);
    final confirmed = effectiveLinks
        .where((l) => l.isConfirmed)
        .toList(growable: false);
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

  @override
  Widget build(BuildContext context) {
    final linksAsync = ref.watch(guardianLinksProvider);
    final userId = ref.watch(authUserIdProvider).value;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    ref.listen(guardianLinksProvider, (prev, next) {
      next.whenData((links) {
        if (!_confirmationListenerInitialized) return;
        final ownLinks = _effectiveLinks(links, userId);
        _notifyNewConfirmations(ownLinks);
      });
    });

    final ownLinks = linksAsync.maybeWhen(
      data: (links) => _effectiveLinks(links, userId),
      orElse: () => _ownLinks(_remoteLinks, userId),
    );
    final allRejected = _allRejected(ownLinks);
    final hasPending = _hasPending(ownLinks);
    final hasConfirmed = ownLinks.any((l) => l.isConfirmed);
    final pendingCount = ownLinks.where((l) => l.isPending).length;

    return LoginStepScaffold(
      step: LoginFlowStep.guardianPending,
      titleOverride: allRejected
          ? 'Verknüpfung abgelehnt'
          : hasConfirmed
              ? 'Verknüpfung bestätigt'
              : 'Bestätigung ausstehend',
      subtitleOverride: allRejected
          ? 'Keines deiner Kinder hat die Anfrage bestätigt.'
          : hasConfirmed
              ? 'Mindestens ein Kind hat bestätigt. Du kannst fortfahren.'
              : pendingCount <= 1
                  ? 'Wir warten auf die Bestätigung durch dein Kind.'
                  : 'Wir warten auf Bestätigungen von $pendingCount Kindern.',
      showPrimaryButton: hasConfirmed && !allRejected,
      submitLabel: 'Weiter',
      submitBusy: _proceeding,
      contentMaxWidth: LoginStepScaffold.defaultContentMaxWidth,
      primaryButtonMaxWidth: LoginStepScaffold.defaultContentMaxWidth,
      onAsyncProceed: (_) async {
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
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: FadeTransition(
                opacity: _pulseAnimation,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: allRejected
                        ? scheme.errorContainer.withValues(alpha: 0.5)
                        : hasConfirmed
                            ? scheme.tertiaryContainer.withValues(alpha: 0.55)
                            : scheme.primaryContainer.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    allRejected
                        ? Icons.link_off_rounded
                        : hasConfirmed
                            ? Icons.check_rounded
                            : Icons.hourglass_top_rounded,
                    size: 42,
                    color: allRejected
                        ? scheme.onErrorContainer
                        : hasConfirmed
                            ? scheme.onTertiaryContainer
                            : scheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (!allRejected && hasPending && !hasConfirmed)
              FadeTransition(
                opacity: _pulseAnimation,
                child: Text(
                  'Warte auf Bestätigung …',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (!allRejected && hasPending && !hasConfirmed)
              const SizedBox(height: 12),
            Text(
              allRejected
                  ? 'Du kannst ein anderes Kind wählen oder es später erneut versuchen.'
                  : hasConfirmed
                      ? 'Tippe auf „Weiter“, um deinen Kalender zu öffnen.'
                      : 'Deine Kinder erhalten eine Push-Benachrichtigung und können '
                          'die Verknüpfung direkt in der App bestätigen.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
            if (ownLinks.isNotEmpty) ...[
              const SizedBox(height: 28),
              GuardianPendingStatusList(
                links: ownLinks,
                reminderBusyLinkId: _reminderBusyLinkId,
                onSendReminder: allRejected ? null : _sendReminder,
              ),
            ],
            const SizedBox(height: 16),
            if (allRejected)
              TextButton(
                onPressed: () => context.go(LoginPaths.selectChild),
                child: const Text('Andere Kinder wählen'),
              )
            else
              TextButton(
                onPressed: () => context.go(LoginPaths.selectChild),
                child: const Text('Weitere Kinder hinzufügen'),
              ),
          ],
        ),
      ),
    );
  }
}
