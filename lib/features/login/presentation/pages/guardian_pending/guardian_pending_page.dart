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
import '../../widgets/login_step_scaffold.dart';

class GuardianPendingPage extends ConsumerStatefulWidget {
  const GuardianPendingPage({super.key});

  @override
  ConsumerState<GuardianPendingPage> createState() =>
      _GuardianPendingPageState();
}

class _GuardianPendingPageState extends ConsumerState<GuardianPendingPage> {
  bool _reminderBusy = false;

  GuardianChildLink? _latestPending(List<GuardianChildLink> links) {
    for (final link in links) {
      if (link.isPending) return link;
    }
    return null;
  }

  Future<void> _sendReminder(GuardianChildLink link) async {
    setState(() => _reminderBusy = true);
    try {
      await ref.read(guardianLinkRepositoryProvider).sendReminder(link.id);
      if (!mounted) return;
      showAppToast(
        context,
        'Erinnerung wurde gesendet.',
        kind: AppToastKind.success,
      );
    } on GuardianLinkRepositoryException catch (e) {
      if (!mounted) return;
      showAppToast(context, e.message, kind: AppToastKind.error);
    } finally {
      if (mounted) setState(() => _reminderBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final linksAsync = ref.watch(guardianLinksProvider);
    final theme = Theme.of(context);

    ref.listen(guardianLinksProvider, (prev, next) {
      next.whenData((links) async {
        final hasConfirmed = links.any((l) => l.isConfirmed);
        if (!hasConfirmed || !context.mounted) return;
        final confirmed = links.firstWhere((l) => l.isConfirmed);
        await ref
            .read(guardianLinkRepositoryProvider)
            .setActiveChild(confirmed.childId);
        await ref.read(profileGateProvider).refresh();
        if (!context.mounted) return;
        context.go(LoginPaths.success);
      });
    });

    final pending = linksAsync.maybeWhen(
      data: _latestPending,
      orElse: () => null,
    );

    return LoginStepScaffold(
      step: LoginFlowStep.guardianPending,
      titleOverride: 'Bestätigung ausstehend',
      subtitleOverride: pending == null
          ? 'Wir warten auf die Bestätigung durch dein Kind.'
          : 'Wir warten auf die Bestätigung durch ${pending.childDisplayName}.',
      showPrimaryButton: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.hourglass_top_rounded,
              size: 56,
              color: theme.colorScheme.primary.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 24),
            Text(
              'Dein Kind erhält eine Push-Benachrichtigung und kann die '
              'Verknüpfung in der App bestätigen.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 32),
            if (pending != null)
              FilledButton(
                onPressed: _reminderBusy
                    ? null
                    : () => _sendReminder(pending),
                child: _reminderBusy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Erinnerung senden'),
              ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.go(LoginPaths.selectChild),
              child: const Text('Anderes Kind wählen'),
            ),
          ],
        ),
      ),
    );
  }
}
