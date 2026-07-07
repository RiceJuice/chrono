import 'package:chronoapp/features/settings/presentation/helpers/settings_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.enabled = true,
    this.isDestructive = false,
    this.onTap,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final bool enabled;
  final bool isDestructive;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveContentColor = enabled
        ? (isDestructive ? scheme.error : scheme.onSurface)
        : scheme.outline;
    final value = subtitle?.trim();

    return InkWell(
      onTap: enabled && onTap != null
          ? () {
              HapticFeedback.selectionClick();
              onTap!();
            }
          : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              PhosphorIcon(
                icon,
                size: 22,
                color: enabled ? scheme.onSurfaceVariant : scheme.outline,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: effectiveContentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (value != null && value.isNotEmpty) ...[
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 130),
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: enabled ? scheme.onSurfaceVariant : scheme.outline,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              trailing ??
                  PhosphorIcon(
                    SettingsIcons.chevron,
                    size: 18,
                    color: enabled ? scheme.onSurfaceVariant : scheme.outline,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
  });

  final String title;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? subtitle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final contentColor = enabled ? scheme.onSurface : scheme.outline;
    final iconColor = enabled ? scheme.onSurfaceVariant : scheme.outline;

    return InkWell(
      onTap: enabled
          ? () {
              HapticFeedback.selectionClick();
              onChanged(!value);
            }
          : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              PhosphorIcon(icon, size: 22, color: iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: contentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 130),
                  child: Text(
                    subtitle!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: enabled ? scheme.onSurfaceVariant : scheme.outline,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: Transform.scale(
                  scale: 0.9,
                  child: Switch(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    value: value,
                    onChanged: enabled
                        ? (next) {
                            HapticFeedback.selectionClick();
                            onChanged(next);
                          }
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
