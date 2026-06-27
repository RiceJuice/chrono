import 'package:chronoapp/features/login/presentation/providers/profile_gate_provider.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_calendar_viewer.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_child_permissions.dart';
import 'package:chronoapp/features/settings/presentation/providers/settings_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Leerer Kalender-Zustand, wenn das Kind keine Bereiche freigegeben hat.
class GuardianCalendarPrivacyEmptyState extends ConsumerWidget {
  const GuardianCalendarPrivacyEmptyState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gate = ref.watch(profileGateDataProvider);
    final ownProfile = ref.watch(syncedProfileProvider).asData?.value;
    if (!isGuardianCalendarViewer(gate: gate, ownProfile: ownProfile)) {
      return const SizedBox.shrink();
    }

    final permissions = ref.watch(activeGuardianChildPermissionsProvider);
    if (permissions.sharesAnyCalendar) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 16),
            Text(
              'Kein Kalender freigegeben',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Dein Kind hat noch keine Kalender-Bereiche freigegeben. '
              'Stundenplan, Speiseplan und Chor können in der App des Kindes '
              'freigeschaltet werden.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Zeigt [child] oder den Privatsphäre-Hinweis für Eltern.
class GuardianCalendarPrivacyGate extends ConsumerWidget {
  const GuardianCalendarPrivacyGate({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gate = ref.watch(profileGateDataProvider);
    final ownProfile = ref.watch(syncedProfileProvider).asData?.value;
    if (!isGuardianCalendarViewer(gate: gate, ownProfile: ownProfile)) {
      return child;
    }

    final permissions = ref.watch(activeGuardianChildPermissionsProvider);
    if (permissions.sharesAnyCalendar) {
      return child;
    }

    return const GuardianCalendarPrivacyEmptyState();
  }
}
