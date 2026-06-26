import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_subject.dart';
import 'package:chronoapp/features/calendar/presentation/providers/subjects_providers.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_form_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Leerer String = bewusst kein Fach gewählt; `null` = Sheet ohne Auswahl geschlossen.
typedef HomeworkSubjectPickerResult = String?;

class HomeworkSubjectPickerRow extends ConsumerWidget {
  const HomeworkSubjectPickerRow({
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

        final selected = _findSubject(subjects, selectedSubjectId);

        return HomeworkFormPickerRow(
          label: 'Fach',
          value: selected?.name ?? 'Keins',
          leading: _SubjectColorDot(
            color: selected?.defaultColor ??
                Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.35),
            emphasized: selected != null,
          ),
          onTap: () async {
            final result = await HomeworkSubjectPickerSheet.show(
              context,
              subjects: subjects,
              selectedSubjectId: selectedSubjectId,
            );
            if (!context.mounted || result == null) return;
            onSubjectChanged(result.isEmpty ? null : result);
          },
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.m,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  CalendarSubject? _findSubject(
    List<CalendarSubject> subjects,
    String? subjectId,
  ) {
    if (subjectId == null) return null;
    for (final subject in subjects) {
      if (subject.id == subjectId) return subject;
    }
    return null;
  }
}

class HomeworkSubjectPickerSheet extends StatelessWidget {
  const HomeworkSubjectPickerSheet({
    super.key,
    required this.subjects,
    required this.selectedSubjectId,
  });

  final List<CalendarSubject> subjects;
  final String? selectedSubjectId;

  static Future<HomeworkSubjectPickerResult> show(
    BuildContext context, {
    required List<CalendarSubject> subjects,
    required String? selectedSubjectId,
  }) {
    return AppModalSheet.show<HomeworkSubjectPickerResult>(
      context: context,
      showDragHandle: true,
      sheetAnimationStyle: kSettingsChoiceSheetMotion,
      builder: (sheetContext) {
        return AppModalSheetChrome(
          child: HomeworkSubjectPickerSheet(
            subjects: subjects,
            selectedSubjectId: selectedSubjectId,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final selectedId = _validSubjectId(subjects, selectedSubjectId);

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.m,
              AppSpacing.xl,
              AppSpacing.s,
            ),
            child: Text(
              'Fach wählen',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.m,
                AppSpacing.xs,
                AppSpacing.m,
                AppSpacing.s,
              ),
              children: [
                _SubjectPickerTile(
                  label: 'Kein Fach',
                  selected: selectedId == null,
                  onTap: () {
                    AppHaptics.selection();
                    Navigator.of(context).pop('');
                  },
                ),
                for (final subject in subjects)
                  _SubjectPickerTile(
                    label: subject.name,
                    color: subject.defaultColor,
                    selected: selectedId == subject.id,
                    onTap: () {
                      AppHaptics.selection();
                      Navigator.of(context).pop(subject.id);
                    },
                  ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.m + bottomInset),
        ],
      ),
    );
  }

  String? _validSubjectId(List<CalendarSubject> subjects, String? subjectId) {
    if (subjectId != null && subjects.any((s) => s.id == subjectId)) {
      return subjectId;
    }
    return null;
  }
}

class _SubjectPickerTile extends StatelessWidget {
  const _SubjectPickerTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.l),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.l,
            vertical: AppSpacing.m,
          ),
          decoration: BoxDecoration(
            color: selected
                ? Color.lerp(
                    scheme.surfaceContainerHighest,
                    color ?? scheme.primary,
                    color == null ? 0.35 : 0.24,
                  )
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.l),
          ),
          child: Row(
            children: [
              _SubjectColorDot(
                color: color ??
                    scheme.onSurfaceVariant.withValues(alpha: 0.35),
                emphasized: color != null,
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      ),
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_rounded,
                  size: 20,
                  color: scheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectColorDot extends StatelessWidget {
  const _SubjectColorDot({
    required this.color,
    required this.emphasized,
  });

  final Color color;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: emphasized ? 12 : 10,
      height: emphasized ? 12 : 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: scheme.outline.withValues(alpha: emphasized ? 0.18 : 0.12),
        ),
        boxShadow: emphasized
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 4,
                  spreadRadius: -1,
                ),
              ]
            : null,
      ),
    );
  }
}
