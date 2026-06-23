import 'package:flutter/material.dart';

import '../../domain/models/guardian_child_link.dart';

Future<bool?> showGuardianLinkConfirmDialog(
  BuildContext context, {
  required GuardianChildLink link,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('Eltern-Verknüpfung'),
      content: Text(
        '${link.guardianDisplayName} möchte sich als Elternteil mit dir '
        'verknüpfen. Nur bestätigte Eltern können deine Kalenderdaten sehen.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Ablehnen'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Bestätigen'),
        ),
      ],
    ),
  );
}
