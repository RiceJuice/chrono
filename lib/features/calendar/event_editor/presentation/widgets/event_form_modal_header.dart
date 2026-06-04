import 'dart:async';
import 'dart:io';

import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/core/widgets/app_glass_icon_button.dart';
import 'package:chronoapp/features/calendar/event_editor/presentation/utils/event_attachment_image_normalizer.dart';
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
    this.contrastImagePath,
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

  /// Liegt der Titel über einem Foto: Kontrastfarbe aus oberem Bildbereich.
  final String? contrastImagePath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
              child: contrastImagePath != null
                  ? _AdaptiveTitleText(
                      title: title,
                      imagePath: contrastImagePath!,
                      textAlign: titleAlign,
                      baseStyle: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : Text(
                      title,
                      textAlign: titleAlign,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        color: scheme.onSurface,
                      ),
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

class _AdaptiveTitleText extends StatefulWidget {
  const _AdaptiveTitleText({
    required this.title,
    required this.imagePath,
    required this.textAlign,
    this.baseStyle,
  });

  final String title;
  final String imagePath;
  final TextAlign textAlign;
  final TextStyle? baseStyle;

  @override
  State<_AdaptiveTitleText> createState() => _AdaptiveTitleTextState();
}

class _AdaptiveTitleTextState extends State<_AdaptiveTitleText> {
  Color? _color;

  @override
  void initState() {
    super.initState();
    _resolveColor();
  }

  @override
  void didUpdateWidget(_AdaptiveTitleText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _resolveColor();
    }
  }

  Future<void> _resolveColor() async {
    final color = await EventAttachmentImageNormalizer.titleColorForImageHeader(
      File(widget.imagePath),
    );
    if (!mounted) return;
    setState(() => _color = color);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = scheme.onSurface;

    return Text(
      widget.title,
      textAlign: widget.textAlign,
      style: (widget.baseStyle ?? const TextStyle(fontSize: 18)).copyWith(
        color: _color ?? fallback,
      ),
    );
  }
}
