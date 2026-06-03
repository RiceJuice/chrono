import 'dart:async';

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
    this.titleAlign = TextAlign.center,
    this.onAttachMedia,
    this.attachingMedia = false,
    this.saveTooltip = 'Speichern',
  });

  final String title;
  final VoidCallback onClose;
  final Future<void> Function() onSave;
  final bool saving;
  final TextAlign titleAlign;

  /// Optional: links neben dem Speichern-Button (z. B. Bild/Datei beim Erstellen).
  final VoidCallback? onAttachMedia;
  final bool attachingMedia;
  final String saveTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showAttach = onAttachMedia != null;

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
            onPressed: () {
              AppHaptics.selection();
              onClose();
            },
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: titleAlign == TextAlign.start ? AppSpacing.s : 0,
                right: showAttach ? AppSpacing.xs : 0,
              ),
              child: Text(
                title,
                textAlign: titleAlign,
                style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),
              ),
            ),
          ),
          if (showAttach) ...[
            AppGlassIconButton(
              icon: AppGlassIconButton.attachMediaIcon,
              tooltip: 'Bild oder Dokument hochladen',
              iconSize: 22,
              preferMaterial: true,
              enabled: !saving && !attachingMedia,
              materialBackgroundColor:
                  theme.colorScheme.surfaceContainerHighest,
              onPressed: () {
                AppHaptics.selection();
                onAttachMedia!();
              },
              child: attachingMedia
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          AppGlassIconButton(
            icon: Icons.check,
            tooltip: saveTooltip,
            iconSize: 22,
            enabled: !saving && !attachingMedia,
            onPressed: () {
              AppHaptics.selection();
              unawaited(onSave());
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
