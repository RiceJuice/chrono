import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/homework/domain/models/homework_task.dart';
import 'package:chronoapp/features/homework/presentation/helpers/homework_due_display.dart';
import 'package:chronoapp/features/homework/presentation/providers/homework_due_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum HomeworkDueMode {
  none,
  nextLesson,
  customDate,
}

class HomeworkDueSection extends ConsumerWidget {
  const HomeworkDueSection({
    super.key,
    required this.selectedSubjectId,
    required this.mode,
    required this.onModeChanged,
  });

  final String? selectedSubjectId;
  final HomeworkDueMode mode;
  final ValueChanged<HomeworkDueMode> onModeChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final chipBg = scheme.surfaceContainerHighest;
    final hasSubject =
        selectedSubjectId != null && selectedSubjectId!.trim().isNotEmpty;
    final nextLessonAsync = hasSubject
        ? ref.watch(nextLessonForSubjectProvider(selectedSubjectId))
        : const AsyncData<CalendarEntry?>(null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Fällig bis',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.s),
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            _DueModeChip(
              label: 'Keine',
              selected: mode == HomeworkDueMode.none,
              chipBackgroundColor: chipBg,
              onSelected: () => onModeChanged(HomeworkDueMode.none),
            ),
            _DueModeChip(
              label: 'Nächste Stunde',
              selected: mode == HomeworkDueMode.nextLesson,
              enabled: hasSubject,
              chipBackgroundColor: chipBg,
              onSelected: hasSubject
                  ? () => onModeChanged(HomeworkDueMode.nextLesson)
                  : null,
            ),
            _DueModeChip(
              label: 'Datum wählen',
              selected: mode == HomeworkDueMode.customDate,
              chipBackgroundColor: chipBg,
              onSelected: () => onModeChanged(HomeworkDueMode.customDate),
            ),
          ],
        ),
        if (mode == HomeworkDueMode.nextLesson) ...[
          const SizedBox(height: AppSpacing.s),
          nextLessonAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, _) => Text(
              'Kalender konnte nicht geladen werden.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                  ),
            ),
            data: (lesson) {
              if (lesson == null) {
                return Text(
                  'Keine kommende Stunde für dieses Fach gefunden.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.error,
                      ),
                );
              }

              final preview = formatHomeworkDueLabel(
                dueAt: lesson.startTime,
                dueSource: HomeworkDueSource.nextLesson,
              );
              return Text(
                preview,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _DueModeChip extends StatelessWidget {
  const _DueModeChip({
    required this.label,
    required this.selected,
    required this.chipBackgroundColor,
    required this.onSelected,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final Color chipBackgroundColor;
  final VoidCallback? onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      labelStyle: TextStyle(
        color: enabled
            ? scheme.onSurface
            : scheme.onSurface.withValues(alpha: 0.38),
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Color.lerp(chipBackgroundColor, scheme.primary, 0.35)!;
        }
        return chipBackgroundColor;
      }),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 6),
      onSelected: enabled && onSelected != null
          ? (_) {
              AppHaptics.selection();
              onSelected!();
            }
          : null,
    );
  }
}
