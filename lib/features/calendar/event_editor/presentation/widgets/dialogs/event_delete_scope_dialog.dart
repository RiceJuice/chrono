import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/core/widgets/app_dialog.dart';
import 'package:flutter/material.dart';

import '../../../domain/calendar_event_save_scope.dart';

/// Fragt beim Löschen eines Serientermins nach dem Umfang.
Future<CalendarEventSaveScope?> showEventDeleteScopeDialog(
  BuildContext context,
) async {
  final theme = Theme.of(context);
  return showAppDialog<CalendarEventSaveScope>(
    context: context,
    title: 'Was soll gelöscht werden?',
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dieser Termin gehört zu einer wiederkehrenden Serie.',
          style: AppDialogTypography.lead(theme),
        ),
        const SizedBox(height: AppSpacing.m),
        Text(
          'Nur dieser Termin — entfernt nur den gewählten Tag.\n'
          'Ganze Serie — löscht alle Wiederholungen.',
          style: AppDialogTypography.hint(theme),
        ),
      ],
    ),
    messageAlign: TextAlign.start,
    actions: [
      AppDialogAction<CalendarEventSaveScope>(
        label: 'Abbrechen',
        role: AppDialogActionRole.cancel,
        onPressed: AppHaptics.selection,
      ),
      AppDialogAction<CalendarEventSaveScope>(
        label: 'Nur dieser Termin',
        role: AppDialogActionRole.normal,
        value: CalendarEventSaveScope.singleInstance,
        onPressed: AppHaptics.selection,
      ),
      AppDialogAction<CalendarEventSaveScope>(
        label: 'Ganze Serie',
        role: AppDialogActionRole.destructive,
        value: CalendarEventSaveScope.entireSeries,
        onPressed: AppHaptics.medium,
      ),
    ],
  );
}
