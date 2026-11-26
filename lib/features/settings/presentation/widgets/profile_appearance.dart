import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

bool get isNativeAppleProfile =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS);

bool get useNativeProfileGlass =>
    isNativeAppleProfile && PlatformVersion.shouldUseNativeGlass;

Color profileAccent(BuildContext context) => isNativeAppleProfile
    ? Theme.of(context).colorScheme.primary
    : const Color(0xff78a995);

Color profileDefaultBackground(BuildContext context) => isNativeAppleProfile
    ? Theme.of(context).colorScheme.primaryContainer
    : const Color(0xffdbece3);

Color profileDefaultForeground(BuildContext context) => isNativeAppleProfile
    ? Theme.of(context).colorScheme.onPrimaryContainer
    : const Color(0xff304d40);

/// Real system buttons on supported Apple OS versions; Material elsewhere.
class ProfileActionButton extends StatelessWidget {
  const ProfileActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.prominent = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    if (useNativeProfileGlass) {
      return CNButton(
        label: label,
        enabled: onPressed != null,
        onPressed: onPressed,
        tint: profileAccent(context),
        config: CNButtonConfig(
          style: prominent ? CNButtonStyle.prominentGlass : CNButtonStyle.glass,
          minHeight: 44,
        ),
      );
    }
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: isNativeAppleProfile
            ? profileAccent(context)
            : profileDefaultForeground(context),
        backgroundColor: prominent ? profileDefaultBackground(context) : null,
        minimumSize: const Size(44, 44),
      ),
      child: Text(label),
    );
  }
}

// Matches the light blue already offered in the app's accent palette.
const profileSelectionBlue = Color(0xff42a5f5);

class ProfileSheetIconButton extends StatelessWidget {
  const ProfileSheetIconButton({
    super.key,
    required this.confirm,
    required this.onPressed,
  });

  final bool confirm;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final label = confirm ? 'Fertig' : 'Abbrechen';
    final color = confirm
        ? profileSelectionBlue
        : Theme.of(context).colorScheme.onSurface;
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        button: true,
        enabled: onPressed != null,
        child: useNativeProfileGlass
            ? CNButton.icon(
                icon: CNSymbol(confirm ? 'checkmark' : 'xmark', size: 25),
                tint: color,
                enabled: onPressed != null,
                onPressed: onPressed,
                config: CNButtonConfig(
                  style: confirm
                      ? CNButtonStyle.prominentGlass
                      : CNButtonStyle.glass,
                  width: 52,
                  minHeight: 52,
                ),
              )
            : IconButton.filledTonal(
                onPressed: onPressed,
                style: IconButton.styleFrom(
                  foregroundColor: color,
                  backgroundColor: confirm
                      ? profileSelectionBlue.withValues(alpha: 0.12)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  minimumSize: const Size(52, 52),
                  iconSize: 28,
                ),
                icon: Icon(confirm ? Icons.check_rounded : Icons.close_rounded),
              ),
      ),
    );
  }
}
