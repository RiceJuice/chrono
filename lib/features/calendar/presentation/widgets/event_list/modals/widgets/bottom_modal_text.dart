import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:flutter/material.dart';

class BottomModalText extends StatelessWidget {
  const BottomModalText({super.key, required this.entry, this.titleStyle});

  final CalendarEntry entry;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final noteText = (entry.note ?? '').trim();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),

          Text(
            entry.eventName,
            style: titleStyle ?? theme.textTheme.titleLarge,
          ),

          if ((entry.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(entry.description!, style: theme.textTheme.bodyMedium),
          ],

          const SizedBox(height: 4),

          Text(
            '${AppDateTime.formatLocalHourMinute(entry.startTime)} - '
            '${AppDateTime.formatLocalHourMinute(entry.endTime)} Uhr',
            style: theme.textTheme.bodyMedium,
          ),

          if ((entry.location ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Ort: ${entry.location!}', style: theme.textTheme.bodyMedium),
          ],

          if (noteText.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.l),
            Container(
              width: double.infinity,
              padding: AppInsets.cardPadding,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.s),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notiz',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(noteText, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
