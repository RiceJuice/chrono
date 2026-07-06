import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_accent_overrides_provider.dart';
import 'package:chronoapp/features/calendar/presentation/theme/calendar_presentation_theme.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/base_calendar_card.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/leading_indicator/calendar_card_leading_indicator.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/lesson_assessment_preview_badge.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/lesson_homework_pending_badge.dart';
import 'package:chronoapp/features/homework/domain/homework_tasks_for_lesson.dart';
import 'package:chronoapp/features/homework/domain/models/homework_task.dart';
import 'package:chronoapp/features/homework/presentation/providers/homework_lesson_providers.dart';
import 'package:chronoapp/features/school_assessments/domain/models/school_assessment_kind.dart';
import 'package:chronoapp/features/school_assessments/domain/school_assessment_lesson_lookup.dart';
import 'package:chronoapp/features/school_assessments/presentation/providers/school_assessment_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LessionCard extends ConsumerWidget {
  final CalendarEntry entry;
  final bool applyPastStyling;
  final bool showTimeColumn;
  final bool weekGridCompact;
  final bool? showInlineTimeRange;
  final double? listTileHorizontalPadding;
  final EdgeInsetsGeometry? contentPadding;
  final double? titleFontSize;
  final bool modalHeaderPreview;
  final double timeColumnCollapse;
  final double? neighborGlassBlurSigma;
  final double? neighborGlassTintAlpha;

  const LessionCard({
    super.key,
    required this.entry,
    this.applyPastStyling = false,
    this.showTimeColumn = true,
    this.weekGridCompact = false,
    this.showInlineTimeRange,
    this.listTileHorizontalPadding,
    this.contentPadding,
    this.titleFontSize,
    this.modalHeaderPreview = false,
    this.timeColumnCollapse = 1,
    this.neighborGlassBlurSigma,
    this.neighborGlassTintAlpha,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = resolveCalendarEntryAccent(ref, entry);
    final isOtherSchoolTrack = isOtherSchoolTrackLessonForRef(ref, entry);
    final lookupKey = lessonHomeworkLookupKeyForEntry(entry);
    final openTasks = lookupKey == null
        ? const <HomeworkTask>[]
        : ref.watch(openHomeworkTasksForLessonKeyProvider(lookupKey));
    final showHomeworkBadge =
        !modalHeaderPreview && openTasks.isNotEmpty;

    final assessmentLookupKey = schoolAssessmentLessonLookupKeyForEntry(entry);
    final assessment = assessmentLookupKey == null
        ? null
        : ref.watch(schoolAssessmentForLessonKeyProvider(assessmentLookupKey));
    final previewAssessment = assessment == null && assessmentLookupKey != null
        ? ref.watch(schoolAssessmentPreviewForLessonKeyProvider(assessmentLookupKey))
        : null;
    final showPreviewBadge =
        !modalHeaderPreview && previewAssessment != null;

    final titleOverride = assessment?.kind.label;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        BaseCalendarCard(
          entry: entry,
          applyPastStyling: applyPastStyling,
          showTimeColumn: showTimeColumn,
          weekGridCompact: weekGridCompact,
          showInlineTimeRange: showInlineTimeRange,
          listTileHorizontalPadding: listTileHorizontalPadding,
          contentPadding:
              contentPadding ?? CalendarCardLeadingIndicator.contentPadding,
          titleFontSize: titleFontSize,
          backgroundColor: _lessonBackgroundColor(
            context,
            accent,
            isOtherSchoolTrack: isOtherSchoolTrack,
            hasAssessment: assessment != null,
          ),
          leadingIndicatorColor: accent,
          modalHeaderPreview: modalHeaderPreview,
          timeColumnCollapse: timeColumnCollapse,
          neighborGlassBlurSigma: neighborGlassBlurSigma,
          neighborGlassTintAlpha: neighborGlassTintAlpha,
          openHomeworkCount: weekGridCompact ? 0 : openTasks.length,
          titleOverride: titleOverride,
        ),
        if (showHomeworkBadge)
          Positioned(
            top: 4,
            right: weekGridCompact ? 4 : AppSpacing.l + 4,
            child: LessonHomeworkPendingBadge(count: openTasks.length),
          ),
        if (showPreviewBadge)
          Positioned(
            top: 4,
            left: weekGridCompact ? 4 : AppSpacing.l + 4,
            child: LessonAssessmentPreviewBadge(kind: previewAssessment.kind),
          ),
      ],
    );
  }

  Color _lessonBackgroundColor(
    BuildContext context,
    Color accent, {
    required bool isOtherSchoolTrack,
    required bool hasAssessment,
  }) {
    var base = CalendarPresentationTheme.lessonCardBackgroundColor(
      context,
      accent,
    );
    if (hasAssessment) {
      base = Color.lerp(base, accent, 0.08) ?? base;
    }
    if (!isOtherSchoolTrack) return base;
    return CalendarPresentationTheme.dimmedSurface(context, base);
  }
}
