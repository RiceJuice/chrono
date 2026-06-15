import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/login_auth_icons.dart';

/// Passwort-Sichtbarkeit — dezentes Phosphor-Icon ohne Material-Splash.
class PasswordVisibilityToggleButton extends StatelessWidget {
  const PasswordVisibilityToggleButton({
    super.key,
    required this.obscured,
    required this.onPressed,
    required this.iconColor,
    this.tooltipObscured = 'Passwort anzeigen',
    this.tooltipVisible = 'Passwort verbergen',
  });

  final bool obscured;
  final VoidCallback onPressed;
  final Color iconColor;
  final String tooltipObscured;
  final String tooltipVisible;

  static const double _iconSize = 18;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        HapticFeedback.selectionClick();
        onPressed();
      },
      tooltip: obscured ? tooltipObscured : tooltipVisible,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      style: IconButton.styleFrom(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: Icon(
          obscured ? LoginAuthIcons.visibilityOff : LoginAuthIcons.visibility,
          key: ValueKey<bool>(obscured),
          size: _iconSize,
          color: iconColor.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}
