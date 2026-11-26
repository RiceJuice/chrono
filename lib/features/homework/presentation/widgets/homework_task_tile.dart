import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/core/widgets/animated_circle_checkbox.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_subject.dart';
import 'package:chronoapp/features/homework/domain/models/homework_task.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_fragment_chip.dart';
import 'package:chronoapp/features/homework/presentation/helpers/homework_due_display.dart';
import 'package:flutter/material.dart';

class HomeworkTaskTile extends StatelessWidget {
  const HomeworkTaskTile({
    super.key,
    required this.task,
    required this.subject,
    this.onToggleCompleted,
    this.isFlagged = false,
  });

  final bool isFlagged;
  final HomeworkTask task;
  final CalendarSubject? subject;
  final ValueChanged<bool>? onToggleCompleted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final completed = task.isCompleted;
    final contentColor = completed
        ? scheme.onSurface.withValues(alpha: 0.45)
        : scheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.s,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: AnimatedCircleCheckbox(
              selected: completed,
              size: 24,
              onChanged: onToggleCompleted == null
                  ? null
                  : (selected) {
                      AppHaptics.selection();
                      onToggleCompleted!(selected);
                    },
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subject != null) ...[
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: subject!.defaultColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s),
                      Expanded(
                        child: Text(
                          subject!.name,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: contentColor.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                if (task.fragments.isNotEmpty) ...[
                  Opacity(
                    opacity: completed ? 0.55 : 1,
                    child: HomeworkFragmentChipRow(
                      fragments: task.fragments,
                      compact: true,
                    ),
                  ),
                ],
                if (task.title.isNotEmpty) ...[
                  _AnimatedStrikeText(
                    text: task.title,
                    completed: completed,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: contentColor,

                      decorationColor: contentColor.withValues(alpha: 0.6),
                    ),
                  ),
                ],
                if (task.displayDescription.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _AnimatedStrikeText(
                    text: task.displayDescription,
                    completed: completed,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: contentColor.withValues(alpha: 0.85),

                      decorationColor: contentColor.withValues(alpha: 0.5),
                    ),
                  ),
                ],
                if (task.dueAt != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Fällig: ${formatHomeworkDueLabel(dueAt: task.dueAt!, dueSource: task.dueSource)}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isHomeworkTaskOverdue(task: task)
                          ? scheme.error.withValues(alpha: 0.85)
                          : contentColor.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isFlagged) ...[
            const SizedBox(width: AppSpacing.m),
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.flag_rounded,
                color: Color(0xFF111827),
                size: 30,
                semanticLabel: 'Markiert',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnimatedStrikeText extends StatelessWidget {
  const _AnimatedStrikeText({
    required this.text,
    required this.completed,
    this.style,
  });
  final String text;
  final bool completed;
  final TextStyle? style;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: completed ? 1 : 0),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 300),
    curve: Curves.easeInOutCubic,
    builder: (context, progress, _) => LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        return CustomPaint(
          foregroundPainter: _StrikePainter(
            painter,
            progress,
            style?.color ?? Theme.of(context).colorScheme.onSurface,
          ),
          child: Text(text, style: style),
        );
      },
    ),
  );
}

class _StrikePainter extends CustomPainter {
  _StrikePainter(this.text, this.progress, this.color);
  final TextPainter text;
  final double progress;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.65)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    for (final line in text.computeLineMetrics()) {
      final y = line.baseline - line.ascent * 0.35;
      canvas.drawLine(
        Offset(line.left, y),
        Offset(line.left + line.width * progress, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StrikePainter old) => true;
}
