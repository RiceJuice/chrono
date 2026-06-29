import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_subject.dart';
import 'package:chronoapp/features/homework/domain/models/homework_task.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_task_tile.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class HomeworkTaskSwipeToDelete extends StatelessWidget {
  const HomeworkTaskSwipeToDelete({
    super.key,
    required this.task,
    required this.subject,
    this.onToggleCompleted,
    this.onConfirmDelete,
  });

  final HomeworkTask task;
  final CalendarSubject? subject;
  final ValueChanged<bool>? onToggleCompleted;
  final Future<bool> Function()? onConfirmDelete;

  static const _itemPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.xl,
    vertical: AppSpacing.s,
  );

  static const _movementDuration = Duration(milliseconds: 280);
  static const _resizeDuration = Duration(milliseconds: 320);

  @override
  Widget build(BuildContext context) {
    final tile = HomeworkTaskTile(
      task: task,
      subject: subject,
      onToggleCompleted: onToggleCompleted,
    );

    if (onConfirmDelete == null) {
      return tile;
    }

    return Dismissible(
      key: ValueKey<String>('homework-task-${task.id}'),
      direction: DismissDirection.endToStart,
      movementDuration: _movementDuration,
      resizeDuration: _resizeDuration,
      confirmDismiss: (_) async {
        final deleted = await onConfirmDelete!();
        if (deleted) {
          AppHaptics.medium();
        } else {
          await AppHaptics.error();
        }
        return deleted;
      },
      background: const Padding(
        padding: _itemPadding,
        child: Align(
          alignment: Alignment.centerRight,
          child: _DeleteActionBubble(),
        ),
      ),
      child: tile,
    );
  }
}

class _DeleteActionBubble extends StatelessWidget {
  const _DeleteActionBubble();

  static const _deleteRed = Color(0xFFE82525);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: _deleteRed,
        shape: AppSquircle.shape(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.m,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Löschen',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.15,
                  ),
            ),
            const SizedBox(width: AppSpacing.s),
            Icon(
              PhosphorIcons.trash(PhosphorIconsStyle.bold),
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
