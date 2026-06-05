import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/core/widgets/app_dialog.dart';
import 'package:flutter/material.dart';

import '../../../domain/calendar_event_change_summary.dart';

/// Fragt nach dem Speichern, ob die Änderung per Push mitgeteilt werden soll.
Future<bool?> showEventBroadcastDialog(
  BuildContext context, {
  required CalendarEventChangeSummary summary,
}) async {
  final theme = Theme.of(context);
  final preview = summary.previewLines;
  final previewCount = preview.length > 3 ? 3 : preview.length;
  final hasDetails = preview.isNotEmpty || summary.audienceChanged;

  return showAppDialog<bool>(
    context: context,
    title: 'Betroffene informieren?',
    message:
        'Möchtest du eine kurze Push-Nachricht über deine Änderungen verschicken?',
    content: hasDetails
        ? Align(
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (preview.isNotEmpty) ...[
                  Text(
                    'Änderungen',
                    style: AppDialogTypography.sectionLabel(theme),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  for (var i = 0; i < previewCount; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i < previewCount - 1 ? AppSpacing.xs : 0,
                      ),
                      child: _DialogBulletLine(
                        text: preview[i],
                        style: AppDialogTypography.listItem(theme),
                      ),
                    ),
                  if (preview.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: _DialogBulletLine(
                        text: 'und ${preview.length - 3} weitere …',
                        style: AppDialogTypography.hint(theme),
                      ),
                    ),
                ] else
                  _DialogBulletLine(
                    text: 'Die sichtbare Zielgruppe wurde angepasst.',
                    style: AppDialogTypography.listItem(theme),
                  ),
              ],
            ),
          )
        : null,
    messageAlign: TextAlign.center,
    actions: [
      AppDialogAction<bool>(
        label: 'Nicht jetzt',
        role: AppDialogActionRole.cancel,
        value: false,
        onPressed: AppHaptics.selection,
      ),
      AppDialogAction<bool>(
        label: 'Benachrichtigen',
        role: AppDialogActionRole.primary,
        value: true,
        onPressed: AppHaptics.medium,
      ),
    ],
  );
}

class _DialogBulletLine extends StatelessWidget {
  const _DialogBulletLine({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('•  ', style: style),
        Expanded(child: Text(text, style: style)),
      ],
    );
  }
}
