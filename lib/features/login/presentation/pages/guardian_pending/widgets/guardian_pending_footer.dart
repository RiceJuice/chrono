import 'package:flutter/material.dart';

import '../../../../domain/models/guardian_child_link.dart';
import '../../credentials/credentials_page.dart';
import '../../email_confirmation/widgets/email_confirmation_ui.dart';

class GuardianPendingFooter extends StatelessWidget {
  const GuardianPendingFooter({
    super.key,
    required this.styles,
    required this.pendingLinks,
    required this.reminderBusyLinkId,
    required this.onReminder,
    required this.onSelectOther,
    required this.onAddChild,
  });

  final EmailConfirmationTextStyles styles;
  final List<GuardianChildLink> pendingLinks;
  final String? reminderBusyLinkId;
  final ValueChanged<GuardianChildLink> onReminder;
  final VoidCallback onSelectOther;
  final VoidCallback onAddChild;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: CredentialsPage.maxFormWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pendingLinks.isNotEmpty) ...[
            Text(
              'Ausstehende Anfragen',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 8),
            for (final link in pendingLinks)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: reminderBusyLinkId == link.id
                      ? null
                      : () => onReminder(link),
                  child: reminderBusyLinkId == link.id
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Erinnerung an ${link.childDisplayName}'),
                ),
              ),
            const SizedBox(height: 8),
          ],
          OutlinedButton(
            onPressed: onSelectOther,
            child: const Text('Andere Kinder wählen'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onAddChild,
            child: const Text('Weiteres Kind hinzufügen'),
          ),
          const SizedBox(height: 20),
          Text(
            'Deine Kinder finden die Anfrage auch in der App, falls die '
            'Benachrichtigung übersehen wurde. Diese Seite aktualisiert sich '
            'automatisch.',
            style: styles.footerMuted,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
