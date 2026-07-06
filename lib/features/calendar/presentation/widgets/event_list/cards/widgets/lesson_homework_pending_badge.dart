import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/lesson_card_indicators.dart';
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

    return LessonCardIndicatorChip(
      icon: Icons.assignment_outlined,
      count: count > 1 ? count : null,
    );
  }
}
