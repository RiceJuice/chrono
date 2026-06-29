import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:flutter/material.dart';

class LessonHomeworkPendingBadge extends StatelessWidget {
  const LessonHomeworkPendingBadge({
    super.key,
    required this.count,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final showCount = count > 1;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
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
            Icon(
              Icons.assignment_outlined,
              size: 11,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
            ),
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
  }
}
