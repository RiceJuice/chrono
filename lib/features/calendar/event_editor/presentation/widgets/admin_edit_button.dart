import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pages/calendar_event_form_page.dart';
import '../providers/is_admin_provider.dart';

/// Kompakter „Bearbeiten“-Chip oben rechts (nur für Admins).
class AdminEditTextButton extends ConsumerWidget {
  const AdminEditTextButton({super.key, required this.entry});

  final CalendarEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    if (!isAdmin) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          AppHaptics.light();
          CalendarEventFormPage.show(context, sourceEntry: entry);
        },
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(
            'Bearbeiten',
            style: theme.textTheme.labelLarge?.copyWith(height: 1.1),
          ),
        ),
      ),
    );
  }
}
