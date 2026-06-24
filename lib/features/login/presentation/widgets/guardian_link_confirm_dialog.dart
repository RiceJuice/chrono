import 'package:flutter/material.dart';

import '../../domain/models/guardian_child_link.dart';

Future<bool?> showGuardianLinkConfirmDialog(
  BuildContext context, {
  required GuardianChildLink link,
  String? guardianNameOverride,
}) {
  final guardianName = _resolveGuardianName(link, guardianNameOverride);
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.family_restroom_rounded,
                size: 30,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Eltern-Verknüpfung',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '$guardianName möchte sich als Elternteil mit dir verknüpfen.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Nur bestätigte Eltern können deine Kalenderdaten sehen.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.65),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Ablehnen'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Bestätigen'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

String _resolveGuardianName(
  GuardianChildLink link,
  String? guardianNameOverride,
) {
  final override = guardianNameOverride?.trim();
  if (override != null && override.isNotEmpty) return override;
  return link.guardianDisplayName;
}
