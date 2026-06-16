import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/calendar_entry.dart';
import '../../../../domain/models/calendar_subject.dart';
import '../../../../presentation/providers/subjects_providers.dart';
import '../../../domain/calendar_event_form_state.dart';

/// Wie Chor-Chips: dezente Fachfarbe im Hintergrund statt Vollfläche.
const double _kSubjectChipAccentMix = 0.52;

class EventSubjectSection extends ConsumerWidget {
  const EventSubjectSection({
    super.key,
    required this.state,
    required this.onChanged,
  });

  final CalendarEventFormState state;
  final ValueChanged<CalendarEventFormState> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.type != CalendarEntryType.lesson || !state.isRecurringEntry) {
      return const SizedBox.shrink();
    }

    final subjectsAsync = ref.watch(subjectsListProvider);
    return subjectsAsync.when(
      data: (subjects) {
        if (subjects.isEmpty) return const SizedBox.shrink();

        final selectedId = _validSubjectId(subjects, state.subjectId);
        final scheme = Theme.of(context).colorScheme;
        final chipBg = scheme.surfaceContainerHighest;

        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Fach',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.s),
              LayoutBuilder(
                builder: (context, constraints) {
                  final maxChipWidth = constraints.maxWidth;
                  return Wrap(
                    spacing: AppSpacing.s,
                    runSpacing: AppSpacing.s,
                    children: [
                      for (final subject in subjects)
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxChipWidth),
                          child: _SubjectChoiceChip(
                            subject: subject,
                            selected: selectedId == subject.id,
                            chipBackgroundColor: chipBg,
                            onSelected: (selected) {
                              AppHaptics.selection();
                              onChanged(
                                state.copyWith(
                                  subjectId: selected ? subject.id : null,
                                  clearSubjectId: !selected,
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.m),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  String? _validSubjectId(List<CalendarSubject> subjects, String? subjectId) {
    if (subjectId != null && subjects.any((s) => s.id == subjectId)) {
      return subjectId;
    }
    return null;
  }
}

class _SubjectChoiceChip extends StatelessWidget {
  const _SubjectChoiceChip({
    required this.subject,
    required this.selected,
    required this.chipBackgroundColor,
    required this.onSelected,
  });

  final CalendarSubject subject;
  final bool selected;
  final Color chipBackgroundColor;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectedFill = Color.lerp(
      chipBackgroundColor,
      subject.defaultColor,
      _kSubjectChipAccentMix,
    )!;

    return ChoiceChip(
      label: _SubjectChipLabel(subject: subject),
      selected: selected,
      showCheckmark: false,
      labelStyle: TextStyle(
        color: scheme.onSurface,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return selectedFill;
        }
        return chipBackgroundColor;
      }),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 6),
      onSelected: onSelected,
    );
  }
}

class _SubjectChipLabel extends StatelessWidget {
  const _SubjectChipLabel({required this.subject});

  final CalendarSubject subject;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: subject.defaultColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: scheme.outline.withValues(alpha: 0.22),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s),
        Flexible(
          child: Text(
            subject.name,
            softWrap: true,
            maxLines: 3,
          ),
        ),
      ],
    );
  }
}
