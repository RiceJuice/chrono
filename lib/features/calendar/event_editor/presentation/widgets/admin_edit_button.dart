import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pages/calendar_event_form_page.dart';
import '../providers/is_admin_provider.dart';

/// Stift-Button rechts oben in Termin-Detail-Sheets (nur für Admins).
class AdminEditButton extends ConsumerWidget {
  const AdminEditButton({
    super.key,
    required this.entry,
    this.topPadding = 6,
    this.rightPadding = 6,
  });

  final CalendarEntry entry;
  final double topPadding;
  final double rightPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    if (!isAdmin) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return Positioned(
      top: topPadding,
      right: rightPadding,
      child: Material(
        color: scheme.surface.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          tooltip: 'Bearbeiten',
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            foregroundColor: scheme.onSurface,
            padding: const EdgeInsets.all(12),
          ),
          onPressed: () {
            AppHaptics.light();
            CalendarEventFormPage.show(context, sourceEntry: entry);
          },
          icon: const Icon(Icons.edit_outlined, size: 18),
        ),
      ),
    );
  }
}
