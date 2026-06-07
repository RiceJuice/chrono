import 'dart:io';

import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'dialogs/event_image_attach_sheet.dart';
import 'event_form_island.dart';

/// Inline-Auswahl unter dem Formular-Header — kein zweites Modal/Dialog.
class EventAttachSourcePanel extends StatelessWidget {
  const EventAttachSourcePanel({
    super.key,
    required this.onSelected,
    this.revealAnimation,
  });

  final ValueChanged<EventImageAttachSource> onSelected;

  /// Gestaffeltes Einblenden der Zeilen (von [EventAttachSourceReveal]).
  final Animation<double>? revealAnimation;

  static bool get isIosSimulator {
    if (kIsWeb || !Platform.isIOS) return false;
    return Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        0,
        AppSpacing.l,
        AppSpacing.s,
      ),
      child: EventFormIsland(
        children: [
          _StaggeredRevealTile(
            index: 0,
            animation: revealAnimation,
            child: _OptionTile(
              icon: Icons.camera_alt_outlined,
              label: 'Foto aufnehmen',
              subtitle: isIosSimulator
                  ? 'Im Simulator nicht verfügbar'
                  : null,
              enabled: !isIosSimulator,
              onTap: () => _select(context, EventImageAttachSource.camera),
            ),
          ),
          _StaggeredRevealTile(
            index: 1,
            animation: revealAnimation,
            child: _OptionTile(
              icon: Icons.photo_library_outlined,
              label: 'Mediathek',
              subtitle: isIosSimulator
                  ? 'Fotos per Drag & Drop in die Mediathek legen'
                  : 'Mehrere Fotos auswählbar',
              onTap: () => _select(context, EventImageAttachSource.gallery),
            ),
          ),
          _StaggeredRevealTile(
            index: 2,
            animation: revealAnimation,
            child: _OptionTile(
              icon: Icons.folder_open_outlined,
              label: 'Datei',
              subtitle: 'Mehrere Dateien auswählbar',
              onTap: () => _select(context, EventImageAttachSource.file),
            ),
          ),
        ],
      ),
    );
  }

  void _select(BuildContext context, EventImageAttachSource source) {
    AppHaptics.selection();
    onSelected(source);
  }
}

class _StaggeredRevealTile extends StatelessWidget {
  const _StaggeredRevealTile({
    required this.index,
    required this.child,
    this.animation,
  });

  final int index;
  final Widget child;
  final Animation<double>? animation;

  @override
  Widget build(BuildContext context) {
    final master = animation;
    if (master == null) return child;

    final start = 0.06 + index * 0.11;
    final end = (start + 0.52).clamp(0.0, 1.0);
    return AnimatedBuilder(
      animation: master,
      builder: (context, child) {
        final t = master.value;
        final progress = ((t - start) / (end - start)).clamp(0.0, 1.0);
        final curved = Curves.easeOutCubic.transform(progress);
        return Opacity(
          opacity: curved,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - curved)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final fg = enabled
        ? scheme.onSurface
        : scheme.onSurface.withValues(alpha: 0.38);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.l,
              vertical: AppSpacing.m,
            ),
            child: Row(
              children: [
                _IconBadge(
                  icon: icon,
                  enabled: enabled,
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: enabled ? 0.9 : 0.55,
                            ),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.enabled,
  });

  final IconData icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(
          alpha: enabled ? 1 : 0.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox.square(
        dimension: 32,
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? scheme.onSurfaceVariant
              : scheme.onSurfaceVariant.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}
