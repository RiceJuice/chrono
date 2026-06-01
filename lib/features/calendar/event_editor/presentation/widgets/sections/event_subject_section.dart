import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/calendar_entry.dart';
import '../../../../domain/models/calendar_subject.dart';
import '../../../../presentation/providers/subjects_providers.dart';
import '../../../domain/calendar_event_form_state.dart';
import '../event_form_island.dart';
import '../event_form_island_row.dart';

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

        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.m),
          child: EventFormIsland(
            children: [
              EventFormIslandRow(
                label: 'Fach',
                trailing: DropdownButton<String?>(
                  value: selectedId,
                  hint: const Text('Fach wählen'),
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (final subject in subjects)
                      DropdownMenuItem<String?>(
                        value: subject.id,
                        child: _SubjectDropdownLabel(subject: subject),
                      ),
                  ],
                  onChanged: (subjectId) {
                    AppHaptics.selection();
                    onChanged(
                      state.copyWith(
                        subjectId: subjectId,
                        clearSubjectId: subjectId == null,
                      ),
                    );
                  },
                ),
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

class _SubjectDropdownLabel extends StatelessWidget {
  const _SubjectDropdownLabel({required this.subject});

  final CalendarSubject subject;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: subject.defaultColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.s),
        Text(subject.name),
      ],
    );
  }
}
