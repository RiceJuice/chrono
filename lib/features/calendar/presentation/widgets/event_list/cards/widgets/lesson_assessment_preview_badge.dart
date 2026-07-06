import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/features/school_assessments/domain/models/school_assessment_kind.dart';
import 'package:flutter/material.dart';

class LessonAssessmentPreviewBadge extends StatelessWidget {
  const LessonAssessmentPreviewBadge({
    super.key,
    required this.kind,
  });

  final SchoolAssessmentKind kind;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: kind.previewTooltipSuffix,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.55),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          child: Icon(
            kind.icon,
            size: 11,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }
}
