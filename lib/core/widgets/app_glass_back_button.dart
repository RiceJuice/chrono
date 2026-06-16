import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/widgets/app_glass_icon_button.dart';
import 'package:flutter/material.dart';

/// Zurück-Button mit nativem Liquid Glass (iOS/macOS 26+) bzw. Material-Fallback.
class AppGlassBackButton extends StatelessWidget {
  const AppGlassBackButton({
    super.key,
    this.onPressed,
    this.enabled = true,
    this.iconSize = 20,
  });

  final VoidCallback? onPressed;
  final bool enabled;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return AppGlassIconButton(
      icon: AppGlassIconButton.backIcon,
      tooltip: 'Zurück',
      iconSize: iconSize,
      enabled: enabled,
      onPressed: enabled
          ? () {
              AppHaptics.selection();
              if (onPressed != null) {
                onPressed!();
              } else {
                Navigator.of(context).pop();
              }
            }
          : null,
    );
  }
}
