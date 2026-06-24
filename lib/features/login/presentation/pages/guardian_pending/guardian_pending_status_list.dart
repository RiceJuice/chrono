import 'package:flutter/material.dart';

import '../../../domain/models/guardian_child_link.dart';

enum GuardianPendingLinkStatus {
  waiting,
  confirmed,
  rejected,
}

GuardianPendingLinkStatus pendingLinkStatus(GuardianChildLink link) {
  if (link.isConfirmed) return GuardianPendingLinkStatus.confirmed;
  if (link.isRejected) return GuardianPendingLinkStatus.rejected;
  return GuardianPendingLinkStatus.waiting;
}

String pendingLinkStatusLabel(GuardianPendingLinkStatus status) {
  return switch (status) {
    GuardianPendingLinkStatus.waiting => 'Wartet',
    GuardianPendingLinkStatus.confirmed => 'Bestätigt',
    GuardianPendingLinkStatus.rejected => 'Abgelehnt',
  };
}

class GuardianPendingStatusList extends StatelessWidget {
  const GuardianPendingStatusList({
    super.key,
    required this.links,
    this.reminderBusyLinkId,
    this.onSendReminder,
  });

  final List<GuardianChildLink> links;
  final String? reminderBusyLinkId;
  final void Function(GuardianChildLink link)? onSendReminder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: links.map((link) {
        final status = pendingLinkStatus(link);
        final chipColors = _chipColors(scheme, status);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          link.childDisplayName,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: chipColors.background,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            pendingLinkStatusLabel(status),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: chipColors.foreground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (status == GuardianPendingLinkStatus.waiting &&
                      onSendReminder != null)
                    TextButton(
                      onPressed: reminderBusyLinkId == link.id
                          ? null
                          : () => onSendReminder!(link),
                      child: reminderBusyLinkId == link.id
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Erinnern'),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }

  ({Color background, Color foreground}) _chipColors(
    ColorScheme scheme,
    GuardianPendingLinkStatus status,
  ) {
    return switch (status) {
      GuardianPendingLinkStatus.waiting => (
          background: scheme.primaryContainer.withValues(alpha: 0.7),
          foreground: scheme.onPrimaryContainer,
        ),
      GuardianPendingLinkStatus.confirmed => (
          background: scheme.tertiaryContainer.withValues(alpha: 0.8),
          foreground: scheme.onTertiaryContainer,
        ),
      GuardianPendingLinkStatus.rejected => (
          background: scheme.errorContainer.withValues(alpha: 0.7),
          foreground: scheme.onErrorContainer,
        ),
    };
  }
}
