import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_subject.dart';
import 'package:chronoapp/features/homework/domain/models/homework_task.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_task_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronoapp/features/homework/presentation/providers/homework_flags_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class HomeworkTaskSwipeToDelete extends ConsumerWidget {
  const HomeworkTaskSwipeToDelete({
    super.key,
    required this.task,
    required this.subject,
    this.onToggleCompleted,
    this.onConfirmDelete,
    this.onEdit,
  });

  final VoidCallback? onEdit;
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
  Widget build(BuildContext context, WidgetRef ref) {
    final flagged =
        ref.watch(homeworkFlagsProvider).asData?.value.contains(task.id) ??
        false;
    Future<void> perform(String action) async {
      if (action == 'edit') onEdit?.call();
      if (action == 'toggle') onToggleCompleted?.call(!task.isCompleted);
      if (action == 'delete') await onConfirmDelete?.call();
      if (action == 'flag') {
        try {
          await ref.read(homeworkFlagsProvider.notifier).toggle(task.id);
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Markierung konnte nicht gespeichert werden.'),
              ),
            );
          }
        }
      }
    }

    final content = HomeworkTaskTile(
      task: task,
      subject: subject,
      isFlagged: flagged,
      onToggleCompleted: onToggleCompleted,
    );
    final apple = !kIsWeb && Theme.of(context).platform == TargetPlatform.iOS;
    final tile = apple && onEdit != null
        ? Stack(
            children: [
              content,
              Positioned.fill(
                left: 64,
                child: _NativeHomeworkMenu(
                  task: task,
                  flagged: flagged,
                  onAction: perform,
                  key: ValueKey('${task.id}-${task.isCompleted}-$flagged'),
                ),
              ),
            ],
          )
        : GestureDetector(
            onLongPressStart: onEdit == null
                ? null
                : (details) async {
                    AppHaptics.medium();
                    final overlay =
                        Overlay.of(context).context.findRenderObject()!
                            as RenderBox;
                    final action = await showMenu<String>(
                      context: context,
                      position: RelativeRect.fromSize(
                        Rect.fromLTWH(
                          details.globalPosition.dx,
                          details.globalPosition.dy,
                          0,
                          0,
                        ),
                        overlay.size,
                      ),
                      items: [
                        PopupMenuItem(
                          value: 'edit',
                          child: const ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Bearbeiten'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: ListTile(
                            leading: Icon(
                              task.isCompleted
                                  ? Icons.radio_button_unchecked
                                  : Icons.check_circle_outline,
                            ),
                            title: Text(
                              task.isCompleted
                                  ? 'Als offen markieren'
                                  : 'Als erledigt markieren',
                            ),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'flag',
                          child: ListTile(
                            leading: Icon(
                              flagged ? Icons.flag : Icons.outlined_flag,
                            ),
                            title: Text(
                              flagged ? 'Markierung entfernen' : 'Markieren',
                            ),
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(
                              Icons.delete_outline,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            title: Text(
                              'Löschen',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                    if (context.mounted && action != null) {
                      await perform(action);
                    }
                  },
            child: content,
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

class _NativeHomeworkMenu extends StatefulWidget {
  const _NativeHomeworkMenu({
    super.key,
    required this.task,
    required this.flagged,
    required this.onAction,
  });
  final HomeworkTask task;
  final bool flagged;
  final Future<void> Function(String) onAction;
  @override
  State<_NativeHomeworkMenu> createState() => _NativeHomeworkMenuState();
}

class _NativeHomeworkMenuState extends State<_NativeHomeworkMenu> {
  MethodChannel? _channel;
  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UiKitView(
    viewType: 'chrono/homework_context_menu',
    // Claim long presses before the surrounding scroll/swipe detectors,
    // then forward the touch sequence to UIKit's context-menu interaction.
    gestureRecognizers: {
      Factory<LongPressGestureRecognizer>(LongPressGestureRecognizer.new),
    },
    creationParams: {
      'completed': widget.task.isCompleted,
      'flagged': widget.flagged,
      'title': widget.task.title,
    },
    creationParamsCodec: const StandardMessageCodec(),
    onPlatformViewCreated: (id) {
      if (!mounted) return;
      _channel = MethodChannel('chrono/homework_context_menu/$id');
      _channel!.setMethodCallHandler((call) async {
        if (call.method == 'action' && mounted) {
          await widget.onAction(call.arguments as String);
        }
      });
    },
  );
}
