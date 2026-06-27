import 'package:chronoapp/core/auth/profile_role_ids.dart';
import 'package:chronoapp/features/login/domain/models/login_flow_role_ids.dart';
import 'package:chronoapp/features/login/presentation/providers/guardian_link_providers.dart';
import 'package:chronoapp/features/login/presentation/providers/profile_gate_provider.dart';
import 'package:chronoapp/features/login/presentation/services/guardian_link_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hinweis für Schüler mit ausstehenden Eltern-Anfragen (Fallback ohne Push).
class GuardianLinkPendingBanner extends ConsumerWidget {
  const GuardianLinkPendingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gate = ref.watch(profileGateDataProvider);
    final role = gate.role?.trim();
    if (role != LoginFlowRoleIds.student && role != ProfileRoleIds.admin) {
      return const SizedBox.shrink();
    }

    final pendingAsync = ref.watch(pendingGuardianLinksProvider);
    return pendingAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (pending) {
        if (pending.isEmpty) return const SizedBox.shrink();

        final count = pending.length;
        final label = count == 1
            ? 'Eine Eltern-Anfrage wartet auf deine Bestätigung'
            : '$count Eltern-Anfragen warten auf deine Bestätigung';

        return Material(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: SafeArea(
            bottom: false,
            child: InkWell(
              onTap: () => GuardianLinkBootstrap.requestProcessQueue(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.family_restroom_rounded,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
