import 'package:flutter/material.dart';
import '../../../domain/models/guardian_child_link.dart';
import '../../../../../../core/theme/theme_tokens.dart';

enum GuardianPendingLinkStatus { waiting, confirmed, rejected, revoked }

GuardianPendingLinkStatus pendingLinkStatus(GuardianChildLink link) =>
    switch (link.status) {
      'pending' => GuardianPendingLinkStatus.waiting,
      'confirmed' => GuardianPendingLinkStatus.confirmed,
      'rejected' => GuardianPendingLinkStatus.rejected,
      _ => GuardianPendingLinkStatus.revoked,
    };
String pendingLinkStatusLabel(GuardianPendingLinkStatus status) =>
    switch (status) {
      GuardianPendingLinkStatus.waiting => 'Bestätigung ausstehend',
      GuardianPendingLinkStatus.confirmed => 'Bestätigt',
      GuardianPendingLinkStatus.rejected => 'Abgelehnt',
      GuardianPendingLinkStatus.revoked => 'Getrennt',
    };

class GuardianPendingStatusList extends StatelessWidget {
  const GuardianPendingStatusList({
    super.key,
    required this.links,
    this.reminderBusyLinkId,
    this.onSendReminder,
    this.onRevoke,
    this.onRequestAgain,
  });
  final List<GuardianChildLink> links;
  final String? reminderBusyLinkId;
  final void Function(GuardianChildLink)? onSendReminder,
      onRevoke,
      onRequestAgain;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final link in links)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.m),
            child: Material(
              color: theme.colorScheme.surfaceContainerHighest,
              shape: AppSquircle.shape(AppRadius.l),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      link.childDisplayName,
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(pendingLinkStatusLabel(pendingLinkStatus(link))),
                    if (link.isPending)
                      const Text(
                        'Anfrage gespeichert. Dein Kind entscheidet in der App.',
                      ),
                    if (link.isConfirmed &&
                        !link.sharePermissions.sharesAnything)
                      const Text(
                        'Verbunden. Dein Kind teilt derzeit keine Inhalte.',
                      ),
                    if (link.isRejected)
                      const Text(
                        'Dein Kind möchte derzeit keine Verbindung. Bitte respektiere seine Entscheidung.',
                      ),
                    if (link.isPending && onSendReminder != null)
                      TextButton(
                        onPressed:
                            reminderBusyLinkId == link.id || !_canRemind(link)
                            ? null
                            : () => onSendReminder!(link),
                        child: Text(
                          _canRemind(link)
                              ? 'Erinnern'
                              : 'Erinnern nach 24 Stunden',
                        ),
                      ),
                    if ((link.isPending || link.isConfirmed) &&
                        onRevoke != null)
                      TextButton(
                        onPressed: () => onRevoke!(link),
                        child: Text(
                          link.isPending
                              ? 'Anfrage zurückziehen'
                              : 'Verbindung trennen',
                        ),
                      ),
                    if ((link.isRejected || link.isRevoked) &&
                        onRequestAgain != null)
                      TextButton(
                        onPressed:
                            (link.respondedAt ?? link.updatedAt) != null &&
                                DateTime.now()
                                        .difference(
                                          (link.respondedAt ?? link.updatedAt)!,
                                        )
                                        .inDays >=
                                    7
                            ? () => onRequestAgain!(link)
                            : null,
                        child: const Text('Erneut anfragen (nach 7 Tagen)'),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  bool _canRemind(GuardianChildLink l) {
    final last = l.reminderSentAt ?? l.requestedAt ?? l.createdAt;
    return last != null && DateTime.now().difference(last).inHours >= 24;
  }
}
