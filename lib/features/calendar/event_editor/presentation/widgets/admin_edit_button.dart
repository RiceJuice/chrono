import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/widgets/app_glass_icon_button.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pages/calendar_event_form_page.dart';
import '../providers/is_admin_provider.dart';

/// Admin-Bearbeiten-Button im Sheet-Header (Glass-Icon wie [LessonAccentButton]).
class AdminEditButton extends ConsumerWidget {
  const AdminEditButton({super.key, required this.entry});

  final CalendarEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    if (!isAdmin) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return AppGlassIconButton(
      icon: Icons.edit_outlined,
      tooltip: 'Bearbeiten',
      materialBackgroundColor: scheme.surface.withValues(alpha: 0.92),
      onPressed: () {
        AppHaptics.light();
        CalendarEventFormPage.show(context, sourceEntry: entry);
      },
    );
  }
}
