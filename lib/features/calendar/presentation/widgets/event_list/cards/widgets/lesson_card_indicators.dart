import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/features/school_assessments/domain/models/school_assessment_kind.dart';
import 'package:flutter/material.dart';

/// Kompakte Pill mit Icon (optional Zähler) — z. B. oben rechts im Wochenraster.
class LessonCardIndicatorChip extends StatelessWidget {
  const LessonCardIndicatorChip({
    super.key,
    required this.icon,
    this.count,
    this.tooltip,
    this.iconColor,
  });

  final IconData icon;
  final int? count;
  final String? tooltip;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final showCount = count != null && count! > 1;
    final effectiveIconColor =
        iconColor ?? scheme.onSurfaceVariant.withValues(alpha: 0.9);

    final chip = DecoratedBox(
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
        padding: EdgeInsets.symmetric(
          horizontal: showCount ? 5 : 4,
          vertical: 3,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: effectiveIconColor),
            if (showCount) ...[
              const SizedBox(width: 2),
              Text(
                '$count',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      height: 1,
                    ),
              ),
            ],
          ],
        ),
      ),
    );

    if (tooltip == null || tooltip!.isEmpty) return chip;
    return Tooltip(message: tooltip, child: chip);
  }
}

/// Gemeinsame Box für Stunden-Indikatoren (Aufgaben + Schultermin), nebeneinander.
class LessonCardIndicatorsBox extends StatelessWidget {
  const LessonCardIndicatorsBox({
    super.key,
    this.homeworkCount = 0,
    this.assessmentKind,
    this.previewAssessmentKind,
    this.compact = false,
  });

  final int homeworkCount;
  final SchoolAssessmentKind? assessmentKind;
  final SchoolAssessmentKind? previewAssessmentKind;

  /// Kompakt: nur Icons in einer Pill (Wochenraster-Ecke).
  final bool compact;

  bool get _hasHomework => homeworkCount > 0;
  bool get _hasAssessment => assessmentKind != null;
  bool get _hasPreview => previewAssessmentKind != null;

  bool get isEmpty => !_hasHomework && !_hasAssessment && !_hasPreview;

  @override
  Widget build(BuildContext context) {
    if (isEmpty) return const SizedBox.shrink();

    if (compact) {
      return _CompactIndicatorsRow(
        homeworkCount: homeworkCount,
        assessmentKind: assessmentKind,
        previewAssessmentKind: previewAssessmentKind,
      );
    }

    return _InlineIndicatorsRow(
      homeworkCount: homeworkCount,
      assessmentKind: assessmentKind,
      previewAssessmentKind: previewAssessmentKind,
    );
  }
}

class _CompactIndicatorsRow extends StatelessWidget {
  const _CompactIndicatorsRow({
    required this.homeworkCount,
    required this.assessmentKind,
    required this.previewAssessmentKind,
  });

  final int homeworkCount;
  final SchoolAssessmentKind? assessmentKind;
  final SchoolAssessmentKind? previewAssessmentKind;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icons = <Widget>[];

    if (homeworkCount > 0) {
      icons.add(_compactIcon(
        context,
        icon: Icons.assignment_outlined,
        count: homeworkCount > 1 ? homeworkCount : null,
      ));
    }

    if (previewAssessmentKind != null && assessmentKind == null) {
      icons.add(
        Tooltip(
          message: previewAssessmentKind!.previewTooltipSuffix,
          child: Icon(
            previewAssessmentKind!.icon,
            size: 11,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
          ),
        ),
      );
    }

    if (assessmentKind != null) {
      icons.add(
        Tooltip(
          message: assessmentKind!.label,
          child: Icon(
            assessmentKind!.icon,
            size: 11,
            color: scheme.primary,
          ),
        ),
      );
    }

    return DecoratedBox(
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _interleave(icons, const SizedBox(width: 5)),
        ),
      ),
    );
  }

  Widget _compactIcon(
    BuildContext context, {
    required IconData icon,
    int? count,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 11,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
        ),
        if (count != null) ...[
          const SizedBox(width: 2),
          Text(
            '$count',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  height: 1,
                ),
          ),
        ],
      ],
    );
  }
}

class _InlineIndicatorsRow extends StatelessWidget {
  const _InlineIndicatorsRow({
    required this.homeworkCount,
    required this.assessmentKind,
    required this.previewAssessmentKind,
  });

  final int homeworkCount;
  final SchoolAssessmentKind? assessmentKind;
  final SchoolAssessmentKind? previewAssessmentKind;

  static const _textHeight = TextHeightBehavior(
    applyHeightToFirstAscent: false,
    applyHeightToLastDescent: false,
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final segments = <Widget>[];

    if (homeworkCount > 0) {
      final label = homeworkCount == 1
          ? 'Noch 1 Aufgabe offen'
          : 'Noch $homeworkCount Aufgaben offen';
      segments.add(
        _iconLabelSegment(
          context,
          icon: Icons.assignment_outlined,
          label: label,
          iconColor: scheme.onSurfaceVariant.withValues(alpha: 0.85),
          textColor: scheme.onSurfaceVariant.withValues(alpha: 0.9),
        ),
      );
    }

    if (previewAssessmentKind != null && assessmentKind == null) {
      segments.add(
        _iconLabelSegment(
          context,
          icon: previewAssessmentKind!.icon,
          label: previewAssessmentKind!.previewTooltipSuffix,
          iconColor: scheme.onSurfaceVariant.withValues(alpha: 0.85),
          textColor: scheme.onSurfaceVariant.withValues(alpha: 0.9),
        ),
      );
    }

    if (assessmentKind != null) {
      segments.add(
        _iconLabelSegment(
          context,
          icon: assessmentKind!.icon,
          label: assessmentKind!.label,
          iconColor: scheme.primary,
          textColor: scheme.primary,
        ),
      );
    }

    if (segments.length == 1) return segments.first;

    final divider = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
      child: SizedBox(
        height: 14,
        child: VerticalDivider(
          width: 1,
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
    );

    return Row(
      children: _interleave(
        segments.map((segment) => Expanded(child: segment)).toList(),
        divider,
      ),
    );
  }

  Widget _iconLabelSegment(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color textColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textHeightBehavior: _textHeight,
            style: theme.textTheme.labelMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

List<Widget> _interleave(List<Widget> items, Widget separator) {
  if (items.isEmpty) return const [];
  final result = <Widget>[items.first];
  for (var i = 1; i < items.length; i++) {
    result.add(separator);
    result.add(items[i]);
  }
  return result;
}
