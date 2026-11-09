import 'dart:async';

import 'package:chronoapp/features/settings/presentation/helpers/settings_icons.dart';
import 'package:flutter/foundation.dart';
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
              _AppleSettingsSwitch(
                title: title,
                enabled: enabled,
                value: value,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppleSettingsSwitch extends StatefulWidget {
  const _AppleSettingsSwitch({
    required this.title,
    required this.enabled,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool enabled;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  State<_AppleSettingsSwitch> createState() => _AppleSettingsSwitchState();
}

class _AppleSettingsSwitchState extends State<_AppleSettingsSwitch> {
  static const _viewType = 'chrono/settings_switch';
  MethodChannel? _channel;
  bool _nativeAvailable = false;

  Map<String, Object> get _configuration => {
    'value': widget.value,
    'enabled': widget.enabled,
    'label': widget.title,
    'isDark': Theme.of(context).brightness == Brightness.dark,
  };

  @override
  void initState() {
    super.initState();
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      unawaited(_checkNativeAvailability());
    }
  }

  Future<void> _checkNativeAvailability() async {
    // A running debug build can receive Dart changes before the native factory.
    final supported = await const MethodChannel(_viewType)
        .invokeMethod<bool>('isAvailable')
        .onError<MissingPluginException>((_, _) => false);
    if (mounted && supported == true) {
      setState(() => _nativeAvailable = true);
    }
  }

  void _onPlatformViewCreated(int id) {
    if (!mounted) return;
    final channel = MethodChannel('$_viewType/$id');
    _channel = channel;
    channel.setMethodCallHandler((call) async {
      if (call.method == 'changed' && widget.enabled) {
        widget.onChanged(call.arguments as bool);
      }
    });
    _updateNativeSwitch();
  }

  void _updateNativeSwitch() {
    unawaited(_channel?.invokeMethod<void>('update', _configuration));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_channel != null) _updateNativeSwitch();
  }

  @override
  void didUpdateWidget(_AppleSettingsSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value ||
        oldWidget.enabled != widget.enabled ||
        oldWidget.title != widget.title) {
      if (_channel != null) _updateNativeSwitch();
    }
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  Widget _buildNativeSwitch() {
    return SizedBox(
      width: 72,
      height: 44,
      child: defaultTargetPlatform == TargetPlatform.iOS
          ? UiKitView(
              viewType: _viewType,
              creationParams: _configuration,
              creationParamsCodec: const StandardMessageCodec(),
              onPlatformViewCreated: _onPlatformViewCreated,
            )
          : AppKitView(
              viewType: _viewType,
              creationParams: _configuration,
              creationParamsCodec: const StandardMessageCodec(),
              onPlatformViewCreated: _onPlatformViewCreated,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_nativeAvailable) return _buildNativeSwitch();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Transform.scale(
        scale: 0.9,
        child: Switch(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          value: widget.value,
          onChanged: widget.enabled
              ? (next) {
                  HapticFeedback.selectionClick();
                  widget.onChanged(next);
                }
              : null,
        ),
      ),
    );
  }
}
