import 'package:chronoapp/core/auth/social_auth_config.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'google_logo_icon.dart';
import 'login_auth_squircle_panel.dart';
import 'login_input_decoration.dart';

enum SocialSignInProvider { google, apple }

enum LoginAuthOptionButtonVariant { apple, google, neutral, primary }

(Color background, Color foreground, Color border) loginAppleButtonColors(
  ColorScheme scheme,
) {
  final isDark = scheme.brightness == Brightness.dark;
  final background = isDark ? Colors.white : Colors.black;
  final foreground = isDark ? Colors.black : Colors.white;
  return (background, foreground, background);
}

/// Google- und Apple-Buttons; optional in Squircle-Box (Startscreen).
class SocialSignInSection extends StatelessWidget {
  const SocialSignInSection({
    super.key,
    required this.busyProvider,
    required this.onGooglePressed,
    required this.onApplePressed,
    this.showDivider = true,
    this.useSquirclePanel = false,
    this.appleLabel = 'Mit Apple fortfahren',
    this.googleLabel = 'Mit Google fortfahren',
    this.trailing,
  });

  /// Höhe des Primary-Buttons (z. B. „Mit E-Mail fortfahren“).
  static const double buttonHeight = 60;

  final SocialSignInProvider? busyProvider;
  final VoidCallback? onGooglePressed;
  final VoidCallback? onApplePressed;
  final bool showDivider;
  final bool useSquirclePanel;
  final String appleLabel;
  final String googleLabel;
  final List<Widget>? trailing;

  static bool get isSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
  }

  @override
  Widget build(BuildContext context) {
    if (!isSupported) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final appleForeground = loginAppleButtonColors(scheme).$2;

    final socialButtons = <Widget>[
      LoginAuthOptionButton(
        label: appleLabel,
        variant: LoginAuthOptionButtonVariant.apple,
        compact: true,
        startScreenStyle: useSquirclePanel,
        leading: Icon(
          Icons.apple,
          size: 22,
          color: appleForeground,
        ),
        isLoading: busyProvider == SocialSignInProvider.apple,
        onPressed: onApplePressed,
      ),
      LoginAuthOptionButton(
        label: googleLabel,
        variant: LoginAuthOptionButtonVariant.google,
        compact: true,
        startScreenStyle: useSquirclePanel,
        leading: const GoogleLogoIcon(),
        isLoading: busyProvider == SocialSignInProvider.google,
        onPressed: isGoogleSignInConfigured ? onGooglePressed : null,
      ),
    ];

    final panel = useSquirclePanel
        ? LoginAuthSquirclePanel(
            socialButtons: socialButtons,
            trailing: trailing ?? const [],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._spaced(socialButtons, AppSpacing.m),
              if (trailing != null) ...[
                const SizedBox(height: AppSpacing.xl + AppSpacing.xs),
                ...trailing!,
              ],
            ],
          );

    if (!showDivider) return panel;

    final dividerColor = scheme.onSurfaceVariant.withValues(
      alpha: AppOpacity.subtle,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: dividerColor)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
              child: Text(
                'oder',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
            Expanded(child: Divider(color: dividerColor)),
          ],
        ),
        const SizedBox(height: AppSpacing.l),
        panel,
      ],
    );
  }

  List<Widget> _spaced(List<Widget> items, double gap) {
    if (items.isEmpty) return items;
    final spaced = <Widget>[items.first];
    for (var i = 1; i < items.length; i++) {
      spaced
        ..add(SizedBox(height: gap))
        ..add(items[i]);
    }
    return spaced;
  }
}

class LoginAuthOptionButton extends StatelessWidget {
  const LoginAuthOptionButton({
    super.key,
    required this.label,
    required this.variant,
    required this.isLoading,
    required this.onPressed,
    this.compact = false,
    this.startScreenStyle = false,
    this.leading,
  });

  final String label;
  final LoginAuthOptionButtonVariant variant;
  final bool compact;
  final bool startScreenStyle;
  final Widget? leading;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPrimary = variant == LoginAuthOptionButtonVariant.primary;

    if (compact && !isPrimary) {
      return _buildCompactButton(context, scheme, startScreenStyle);
    }

    return _buildPrimaryStyleButton(context, scheme, isPrimary);
  }

  Widget _buildCompactButton(
    BuildContext context,
    ColorScheme scheme,
    bool startScreenStyle,
  ) {
    final (backgroundColor, textColor, borderColor) = switch (variant) {
      LoginAuthOptionButtonVariant.apple => loginAppleButtonColors(scheme),
      LoginAuthOptionButtonVariant.google when startScreenStyle => (
          scheme.surfaceContainerHighest,
          scheme.onSurface,
          scheme.surfaceContainerHighest,
        ),
      LoginAuthOptionButtonVariant.google => (
          scheme.surfaceContainer,
          scheme.onSurface,
          scheme.surfaceContainerHighest,
        ),
      _ when startScreenStyle => (
          scheme.surfaceContainerHighest,
          scheme.onSurface,
          scheme.surfaceContainerHighest,
        ),
      _ => (
          scheme.surfaceContainer,
          scheme.onSurface,
          scheme.surfaceContainerHighest,
        ),
    };

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: kLoginSocialButtonPadding,
          minimumSize: const Size(0, 52),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: BorderSide(color: borderColor, width: 1),
          shape: AppSquircle.shape(AppRadius.s),
        ),
        child: _buildChild(textColor, compact: true),
      ),
    );
  }

  Widget _buildPrimaryStyleButton(
    BuildContext context,
    ColorScheme scheme,
    bool isPrimary,
  ) {
    final themeStyle = Theme.of(context).elevatedButtonTheme.style;
    final baseStyle = themeStyle ??
        ElevatedButton.styleFrom(
          padding: AppInsets.buttonContentWide,
          minimumSize: const Size(0, SocialSignInSection.buttonHeight),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: AppSquircle.shape(AppRadius.s),
        );
    final backgroundColor =
        isPrimary ? scheme.primary : scheme.surfaceContainerHighest;
    final foregroundColor = isPrimary ? Colors.black : scheme.onSurface;

    return SizedBox(
      height: SocialSignInSection.buttonHeight,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return backgroundColor.withValues(alpha: AppOpacity.disabled);
            }
            return backgroundColor;
          }),
          foregroundColor: WidgetStatePropertyAll(foregroundColor),
          minimumSize: const WidgetStatePropertyAll(
            Size(double.infinity, SocialSignInSection.buttonHeight),
          ),
        ),
        child: _buildChild(foregroundColor, compact: false),
      ),
    );
  }

  Widget _buildChild(Color foregroundColor, {required bool compact}) {
    if (isLoading) {
      return SizedBox(
        height: compact ? 20 : 24,
        width: compact ? 20 : 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: AppSpacing.s),
        ],
        Text(
          label,
          style: TextStyle(
            fontWeight: compact ? FontWeight.w600 : FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
