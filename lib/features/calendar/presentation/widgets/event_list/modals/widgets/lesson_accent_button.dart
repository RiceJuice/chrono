import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/widgets/app_glass_icon_button.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/domain/preview/calendar_appearance_config.dart';
import 'package:chronoapp/features/calendar/domain/preview/calendar_settings_kind.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_header/calendar_appearance_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Paletten-Button oben rechts in Unterrichts-Detail-Sheets.
class LessonAccentButton extends ConsumerWidget {
  const LessonAccentButton({
    super.key,
    required this.entry,
    this.onAccentPressed,
  });

  final CalendarEntry entry;

  /// Wenn gesetzt, übernimmt der Host die Präsentation (z. B. Morph im Sheet).
  final VoidCallback? onAccentPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (entry.type != CalendarEntryType.lesson) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final subjectId = entry.subjectId;

    return AppGlassIconButton(
      icon: Icons.palette_outlined,
      tooltip: 'Farbe anpassen',
      materialBackgroundColor: scheme.surface.withValues(alpha: 0.92),
      onPressed: () {
        if (onAccentPressed != null) {
          onAccentPressed!();
          return;
        }
        AppHaptics.light();
        final config = subjectId != null
            ? CalendarAppearanceBySubject(
                subjectId: subjectId,
                previewEntry: entry,
              )
            : const CalendarAppearanceByKind(CalendarSettingsKind.school);
        CalendarAppearanceBottomSheet.show(context, config: config);
      },
    );
  }
}
