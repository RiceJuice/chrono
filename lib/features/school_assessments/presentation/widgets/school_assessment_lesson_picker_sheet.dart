import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/school_assessments/presentation/widgets/school_assessment_date_picker_sheet.dart';
import 'package:flutter/material.dart';

typedef SchoolAssessmentLessonLabelFormatter = String Function(CalendarEntry);

class SchoolAssessmentLessonPickerSheet extends StatelessWidget {
  const SchoolAssessmentLessonPickerSheet({
    super.key,
    required this.lessons,
    required this.selectedLesson,
    this.title = 'Stunde wählen',
    this.formatLabel = formatSchoolAssessmentLessonLabel,
  });

  final List<CalendarEntry> lessons;
  final CalendarEntry? selectedLesson;
  final String title;
  final SchoolAssessmentLessonLabelFormatter formatLabel;

  static Future<CalendarEntry?> show(
    BuildContext context, {
    required List<CalendarEntry> lessons,
    required CalendarEntry? selectedLesson,
    String title = 'Stunde wählen',
    SchoolAssessmentLessonLabelFormatter? formatLabel,
  }) {
    return AppModalSheet.show<CalendarEntry>(
      context: context,
      showDragHandle: true,
      sheetAnimationStyle: kSettingsChoiceSheetMotion,
      builder: (sheetContext) {
        return AppModalSheetChrome(
          child: SchoolAssessmentLessonPickerSheet(
            lessons: lessons,
            selectedLesson: selectedLesson,
            title: title,
            formatLabel: formatLabel ?? formatSchoolAssessmentLessonLabel,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final scheme = Theme.of(context).colorScheme;
    final selectedId = selectedLesson?.id;

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
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          if (lessons.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                'Keine Stunde an diesem Tag.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            )
          else
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
                  for (final lesson in lessons)
                    _LessonPickerTile(
                      label: formatLabel(lesson),
                      selected: lesson.id == selectedId,
                      onTap: () {
                        AppHaptics.selection();
                        Navigator.of(context).pop(lesson);
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
}

class _LessonPickerTile extends StatelessWidget {
  const _LessonPickerTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

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
                ? scheme.surfaceContainerHighest
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.l),
          ),
          child: Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 18,
                color: scheme.onSurfaceVariant,
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
