import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:flutter/material.dart';

class EventFormModalHeader extends StatelessWidget {
  const EventFormModalHeader({
    super.key,
    required this.title,
    required this.onClose,
    required this.onSave,
    this.saving = false,
  });

  final String title;
  final VoidCallback onClose;
  final VoidCallback onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s,
        AppSpacing.m,
        AppSpacing.s,
        AppSpacing.s,
      ),
      child: Row(
        children: [
          _HeaderIconButton(
            icon: Icons.close,
            tooltip: 'Schließen',
            onPressed: () {
              AppHaptics.selection();
              onClose();
            },
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),
            ),
          ),
          _HeaderIconButton(
            icon: Icons.check,
            tooltip: 'Speichern',
            onPressed: saving
                ? null
                : () {
                    AppHaptics.selection();
                    onSave();
                  },
            child: saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.child,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerHighest,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        icon: child ?? Icon(icon, size: 22),
      ),
    );
  }
}
