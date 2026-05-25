import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:flutter/material.dart';

import '../../../domain/calendar_event_save_scope.dart';

/// Fragt beim Speichern eines Serientermins nach dem Umfang.
Future<CalendarEventSaveScope?> showEventSaveScopeDialog(
  BuildContext context,
) async {
  return showDialog<CalendarEventSaveScope>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return AlertDialog(
        title: const Text('Änderungen speichern'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dieser Termin gehört zu einer Serie. Was möchtest du speichern?',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              '„Nur diesen Termin“ ändert die Ausnahme für einen Tag. '
              '„Ganze Serie“ passt Wiederholung, Serienzeitraum und Uhrzeit an.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              AppHaptics.selection();
              Navigator.of(context).pop();
            },
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              AppHaptics.selection();
              Navigator.of(context).pop(
                CalendarEventSaveScope.singleInstance,
              );
            },
            child: const Text('Nur diesen Termin'),
          ),
          FilledButton(
            onPressed: () {
              AppHaptics.medium();
              Navigator.of(context).pop(
                CalendarEventSaveScope.entireSeries,
              );
            },
            child: const Text('Ganze Serie'),
          ),
        ],
      );
    },
  );
}
