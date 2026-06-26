import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_subject.dart';
import 'package:chronoapp/features/calendar/event_editor/presentation/widgets/event_form_island.dart';
import 'package:chronoapp/features/calendar/presentation/providers/subjects_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const String _kNoSubjectValue = '__none__';

class HomeworkSubjectSection extends ConsumerWidget {
  const HomeworkSubjectSection({
    super.key,
    required this.selectedSubjectId,
    required this.onSubjectChanged,
  });

  final String? selectedSubjectId;
  final ValueChanged<String?> onSubjectChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsListProvider);

    return subjectsAsync.when(
      data: (subjects) {
        if (subjects.isEmpty) return const SizedBox.shrink();

        final selectedId = _validSubjectId(subjects, selectedSubjectId);
        final scheme = Theme.of(context).colorScheme;

        return Column(
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
            EventFormIsland(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.l,
                    vertical: AppSpacing.xs,
                  ),
                  child: DropdownMenu<String>(
                    width: double.infinity,
                    initialSelection: selectedId ?? _kNoSubjectValue,
                    hintText: 'Fach auswählen',
                    textStyle: Theme.of(context).textTheme.bodyLarge,
                    trailingIcon: Icon(
                      Icons.arrow_drop_down,
                      color: scheme.onSurfaceVariant,
                    ),
                    inputDecorationTheme: const InputDecorationTheme(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSelected: (value) {
                      AppHaptics.selection();
                      if (value == null || value == _kNoSubjectValue) {
                        onSubjectChanged(null);
                        return;
                      }
                      onSubjectChanged(value);
                    },
                    dropdownMenuEntries: [
                      const DropdownMenuEntry(
                        value: _kNoSubjectValue,
                        label: 'Kein Fach',
                      ),
                      for (final subject in subjects)
                        DropdownMenuEntry(
                          value: subject.id,
                          label: subject.name,
                          labelWidget: _SubjectDropdownLabel(subject: subject),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
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
    if (subjectId != null && subjects.any((subject) => subject.id == subjectId)) {
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
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
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
        const SizedBox(width: AppSpacing.s),
        Expanded(child: Text(subject.name)),
      ],
    );
  }
}
