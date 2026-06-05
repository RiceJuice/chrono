import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/core/widgets/app_dialog.dart';
import 'package:flutter/material.dart';

import '../../../domain/calendar_event_save_scope.dart';

/// Fragt beim Speichern eines Serientermins nach dem Umfang.
Future<CalendarEventSaveScope?> showEventSaveScopeDialog(
  BuildContext context,
) async {
  final theme = Theme.of(context);
  return showAppDialog<CalendarEventSaveScope>(
    context: context,
    title: 'Was soll gespeichert werden?',
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
          'Nur dieser Termin — gilt nur für den gewählten Tag.\n'
          'Ganze Serie — gilt für alle Wiederholungen.',
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
        role: AppDialogActionRole.primary,
        value: CalendarEventSaveScope.entireSeries,
        onPressed: AppHaptics.medium,
      ),
    ],
  );
}
