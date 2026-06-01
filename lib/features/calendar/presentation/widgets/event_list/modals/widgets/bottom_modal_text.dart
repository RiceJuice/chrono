import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:flutter/material.dart';

class BottomModalText extends StatelessWidget {
  const BottomModalText({
    super.key,
    required this.entry,
    this.titleStyle,
    this.topSpacing = 30,
  });

  final CalendarEntry entry;
  final TextStyle? titleStyle;

  /// Abstand oberhalb des Titels (z. B. kleiner direkt unter Bildern).
  final double topSpacing;

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
          SizedBox(height: topSpacing),

          Text(
            entry.eventName,
            style: titleStyle ?? theme.textTheme.titleLarge,
          ),

          if ((entry.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(entry.description!, style: theme.textTheme.bodyMedium),
          ],

          const SizedBox(height: 4),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.schedule_outlined,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${AppDateTime.formatLocalHourMinute(entry.startTime)} – '
                  '${AppDateTime.formatLocalHourMinute(entry.endTime)} Uhr',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),

          if ((entry.location ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.place_outlined,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.location!.trim(),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
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
