import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/event_editor/presentation/providers/is_admin_provider.dart';
import 'package:chronoapp/features/calendar/event_editor/presentation/widgets/admin_edit_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BottomModalText extends ConsumerWidget {
  const BottomModalText({super.key, required this.entry, this.titleStyle});

  final CalendarEntry entry;
  final TextStyle? titleStyle;

  static const double _kAdminButtonReserveWidth = 108;
  static const double _kAdminButtonInsetRight = 6;
  static const double _kContentTop = AppSpacing.m;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final noteText = (entry.note ?? '').trim();
    final isAdmin = ref.watch(isAdminProvider);

    final contentRight = isAdmin
        ? _kAdminButtonReserveWidth + _kAdminButtonInsetRight
        : AppSpacing.l;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: _kContentTop),
            Container(
              margin: EdgeInsets.fromLTRB(AppSpacing.l, 0, contentRight, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildTextContent(theme, scheme, noteText),
              ),
            ),
          ],
        ),
        Positioned(
          top: _kContentTop,
          right: _kAdminButtonInsetRight,
          child: AdminEditTextButton(entry: entry),
        ),
      ],
    );
  }

  List<Widget> _buildTextContent(
    ThemeData theme,
    ColorScheme scheme,
    String noteText,
  ) {
    return [
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
    ];
  }
}
