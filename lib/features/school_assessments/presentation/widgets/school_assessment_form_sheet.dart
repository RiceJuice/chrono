import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:chronoapp/core/widgets/app_sheet_drag_handle.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/providers/filter/calendar/calendar_filtered_entries_providers.dart';
import 'package:chronoapp/features/homework/presentation/providers/homework_providers.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_form_shell.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_subject_section.dart';
import 'package:chronoapp/features/school_assessments/domain/models/school_assessment_kind.dart';
import 'package:chronoapp/features/school_assessments/domain/models/school_assessment_schedule_source.dart';
import 'package:chronoapp/features/school_assessments/domain/upcoming_lessons_for_subject.dart';
import 'package:chronoapp/features/school_assessments/presentation/providers/school_assessment_providers.dart';
import 'package:chronoapp/features/school_assessments/presentation/widgets/school_assessment_date_picker_sheet.dart';
import 'package:chronoapp/features/school_assessments/presentation/widgets/school_assessment_lesson_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class SchoolAssessmentFormSheet extends ConsumerStatefulWidget {
  const SchoolAssessmentFormSheet({
    super.key,
    this.initialSubjectId,
    this.initialLesson,
    this.embedded = false,
  });

  final String? initialSubjectId;
  final CalendarEntry? initialLesson;
  final bool embedded;

  static Future<void> show(
    BuildContext context, {
    String? initialSubjectId,
    CalendarEntry? initialLesson,
  }) {
    return AppModalSheet.show<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      sheetAnimationStyle: kSettingsChoiceSheetMotion,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (sheetContext) {
        return AppModalSheetChrome(
          constraints: appModalChoiceSheetConstraints(sheetContext),
          child: SchoolAssessmentFormSheet(
            initialSubjectId: initialSubjectId,
            initialLesson: initialLesson,
          ),
        );
      },
    );
  }

  @override
  ConsumerState<SchoolAssessmentFormSheet> createState() =>
      _SchoolAssessmentFormSheetState();
}

class _SchoolAssessmentFormSheetState
    extends ConsumerState<SchoolAssessmentFormSheet> {
  late SchoolAssessmentKind _kind;
  String? _selectedSubjectId;
  DateTime? _selectedDay;
  CalendarEntry? _selectedLesson;
  bool _saving = false;
  String? _errorMessage;
  bool _autoSubjectApplied = false;

  @override
  void initState() {
    super.initState();
    _kind = SchoolAssessmentKind.schulaufgabe;
    _selectedSubjectId = widget.initialSubjectId;
    final initialLesson = widget.initialLesson;
    if (initialLesson != null) {
      _selectedDay = AppDateTime.localDay(initialLesson.startTime);
      _selectedLesson = initialLesson;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyAutoSubject();
        _applyDefaultDay();
      });
    }
  }

  void _applyAutoSubject() {
    if (_autoSubjectApplied || _selectedSubjectId != null) return;
    final subjectId = ref.read(currentSubjectIdProvider);
    if (subjectId == null || subjectId.isEmpty) return;
    setState(() {
      _selectedSubjectId = subjectId;
      _autoSubjectApplied = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyDefaultDay());
  }

  void _applyDefaultDay() {
    final subjectId = _selectedSubjectId?.trim();
    if (subjectId == null || subjectId.isEmpty) return;
    if (_selectedDay != null && _selectedLesson != null) return;

    final entries = ref.read(filteredCalendarAllEntriesProvider).asData?.value;
    if (entries == null) return;

    final nextLessons = upcomingLessonsForSubject(
      entries: entries,
      subjectId: subjectId,
      limit: 1,
    );
    if (nextLessons.isEmpty || !mounted) return;

    final lesson = nextLessons.first;
    setState(() {
      _selectedDay = AppDateTime.localDay(lesson.startTime);
      _selectedLesson = lesson;
    });
  }

  void _onSubjectChanged(String? subjectId) {
    setState(() {
      _selectedSubjectId = subjectId;
      _selectedDay = null;
      _selectedLesson = null;
      _errorMessage = null;
    });
    if (subjectId != null && subjectId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _applyDefaultDay());
    }
  }

  void _onDayChanged(DateTime day) {
    final subjectId = _selectedSubjectId?.trim();
    if (subjectId == null || subjectId.isEmpty) return;

    final entries = ref.read(filteredCalendarAllEntriesProvider).asData?.value;
    if (entries == null) return;

    final lessons = lessonsForSubjectOnLocalDay(
      entries: entries,
      subjectId: subjectId,
      day: day,
    );

    setState(() {
      _selectedDay = AppDateTime.localDay(day);
      _selectedLesson = lessons.isEmpty ? null : lessons.first;
      _errorMessage = null;
    });
  }

  bool get _hasSubject =>
      _selectedSubjectId != null && _selectedSubjectId!.trim().isNotEmpty;

  bool get _canCreate =>
      _hasSubject && _selectedDay != null && _selectedLesson != null && !_saving;

  String? _dayLabel() {
    if (_selectedDay == null) return null;
    return formatSchoolAssessmentCustomDayLabel(_selectedDay!);
  }

  String? _timeLabel() {
    if (_selectedLesson == null) return null;
    return formatSchoolAssessmentTimeLabel(_selectedLesson!);
  }

  Future<void> _pickDay() async {
    final subjectId = _selectedSubjectId?.trim();
    if (subjectId == null || subjectId.isEmpty) return;

    final picked = await SchoolAssessmentDatePickerSheet.show(
      context,
      initialDate: _selectedDay ?? AppDateTime.nowLocal(),
      subjectId: subjectId,
    );
    if (!mounted || picked == null) return;
    _onDayChanged(picked);
  }

  Future<void> _pickLesson() async {
    final subjectId = _selectedSubjectId?.trim();
    final day = _selectedDay;
    if (subjectId == null || subjectId.isEmpty || day == null) return;

    final entries = ref.read(filteredCalendarAllEntriesProvider).asData?.value;
    if (entries == null) return;

    final lessons = lessonsForSubjectOnLocalDay(
      entries: entries,
      subjectId: subjectId,
      day: day,
    );

    if (lessons.isEmpty) {
      setState(() {
        _errorMessage = 'Keine Stunde an diesem Tag für dieses Fach.';
      });
      return;
    }

    final picked = await SchoolAssessmentLessonPickerSheet.show(
      context,
      lessons: lessons,
      selectedLesson: _selectedLesson,
      title: 'Stunde wählen',
      formatLabel: formatSchoolAssessmentTimeLabel,
    );
    if (!mounted || picked == null) return;
    setState(() {
      _selectedLesson = picked;
      _errorMessage = null;
    });
  }

  Future<void> _onCreate() async {
    if (!_canCreate) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await ref.read(schoolAssessmentActionsProvider).create((
        kind: _kind,
        subjectId: _selectedSubjectId!.trim(),
        scheduledAt: _selectedLesson!.startTime,
        scheduleSource: SchoolAssessmentScheduleSource.lessonSlot,
      ));
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Klausur konnte nicht gespeichert werden.';
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(filteredCalendarAllEntriesProvider, (previous, next) {
      if (!_hasSubject || _saving) return;
      if (_selectedDay != null && _selectedLesson != null) return;
      next.whenData((_) => _applyDefaultDay());
    });
    ref.watch(filteredCalendarAllEntriesProvider);

    final scheme = Theme.of(context).colorScheme;
    final bottomInset = widget.embedded
        ? MediaQuery.viewInsetsOf(context).bottom
        : MediaQuery.paddingOf(context).bottom;

    final formContent = _buildFormContent(
      context,
      scheme: scheme,
      bottomInset: bottomInset,
    );

    if (widget.embedded) {
      return SafeArea(
        top: false,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: formContent),
          ],
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSheetDragHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.s,
              AppSpacing.xl,
              AppSpacing.m,
            ),
            child: Text(
              'Klausur erstellen',
              textAlign: TextAlign.center,
              style: GoogleFonts.libreBaskerville(
                textStyle: Theme.of(context).textTheme.titleLarge,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
          Flexible(child: formContent),
        ],
      ),
    );
  }

  Widget _buildFormContent(
    BuildContext context, {
    required ColorScheme scheme,
    required double bottomInset,
  }) {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      shrinkWrap: !widget.embedded,
      padding: EdgeInsets.fromLTRB(
        widget.embedded ? AppSpacing.xl : AppSpacing.l,
        widget.embedded ? AppSpacing.l : 0,
        widget.embedded ? AppSpacing.xl : AppSpacing.l,
        AppSpacing.l + bottomInset,
      ),
      children: [
        Text(
          'Termin-Typ',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.s),
        Row(
          children: [
            for (var i = 0; i < SchoolAssessmentKind.values.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.s),
              Expanded(
                child: _KindTypeCard(
                  kind: SchoolAssessmentKind.values[i],
                  selected: _kind == SchoolAssessmentKind.values[i],
                  onTap: () {
                    AppHaptics.selection();
                    setState(() => _kind = SchoolAssessmentKind.values[i]);
                  },
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        HomeworkFormGroup(
          children: [
            HomeworkSubjectPickerRow(
              selectedSubjectId: _selectedSubjectId,
              onSubjectChanged: _onSubjectChanged,
            ),
            HomeworkFormPickerRow(
              label: 'Tag',
              value: _dayLabel(),
              enabled: _hasSubject,
              leading: Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              onTap: _hasSubject ? _pickDay : null,
            ),
            HomeworkFormPickerRow(
              label: 'Stunde',
              value: _timeLabel(),
              enabled: _hasSubject && _selectedDay != null,
              leading: Icon(
                Icons.schedule_outlined,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              onTap: _hasSubject && _selectedDay != null ? _pickLesson : null,
            ),
          ],
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: AppSpacing.m),
          HomeworkFormInfoBanner(
            message: _errorMessage!,
            icon: Icons.error_outline_rounded,
            tone: HomeworkFormInfoTone.error,
          ),
        ],
        const SizedBox(height: AppSpacing.l),
        HomeworkFormFooter(
          busy: _saving,
          submitEnabled: _canCreate,
          submitLabel: 'Speichern',
          onSubmit: () {
            AppHaptics.light();
            _onCreate();
          },
        ),
      ],
    );
  }
}

class _KindTypeCard extends StatelessWidget {
  const _KindTypeCard({
    required this.kind,
    required this.selected,
    required this.onTap,
  });

  final SchoolAssessmentKind kind;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.m),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s,
            vertical: AppSpacing.m,
          ),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primaryContainer.withValues(alpha: 0.65)
                : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.m),
            border: Border.all(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.55)
                  : scheme.outlineVariant.withValues(alpha: 0.25),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                kind.icon,
                size: 22,
                color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                kind.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant,
                      height: 1.15,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
