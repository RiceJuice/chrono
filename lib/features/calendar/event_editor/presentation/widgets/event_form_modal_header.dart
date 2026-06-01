import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/core/widgets/app_glass_icon_button.dart';
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
          AppGlassIconButton(
            icon: Icons.close,
            tooltip: 'Schließen',
            iconSize: 22,
            materialBackgroundColor:
                theme.colorScheme.surfaceContainerHighest,
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
          AppGlassIconButton(
            icon: Icons.check,
            tooltip: 'Speichern',
            iconSize: 22,
            enabled: !saving,
            materialBackgroundColor:
                theme.colorScheme.surfaceContainerHighest,
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
                : null,
          ),
        ],
      ),
    );
  }
}
