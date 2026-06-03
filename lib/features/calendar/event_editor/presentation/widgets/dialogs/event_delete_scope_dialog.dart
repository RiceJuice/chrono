import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:flutter/material.dart';

import '../../../domain/calendar_event_save_scope.dart';

/// Fragt beim Löschen eines Serientermins nach dem Umfang.
Future<CalendarEventSaveScope?> showEventDeleteScopeDialog(
  BuildContext context,
) async {
  return showDialog<CalendarEventSaveScope>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return AlertDialog(
        title: const Text('Termin löschen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dieser Termin gehört zu einer Serie. Was möchtest du löschen?',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              '„Nur diesen Termin“ entfernt die gewählte Instanz. '
              '„Ganze Serie“ löscht alle Wiederholungen.',
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
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
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
