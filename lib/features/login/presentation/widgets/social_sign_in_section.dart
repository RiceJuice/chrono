import 'package:chronoapp/core/auth/social_auth_config.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../utils/login_auth_icons.dart';
import '../utils/login_layout_utils.dart';
import 'google_logo_icon.dart';
import 'login_auth_squircle_panel.dart';
import 'login_input_decoration.dart';

enum SocialSignInProvider { google, apple }

enum LoginAuthOptionButtonVariant { apple, google, neutral, primary }

/// Startscreen: volle Buttons in Squircle-Box. Credentials: volle Breite inline.
enum SocialSignInPresentation { startSheet, inline }

(Color background, Color foreground, Color border) loginAppleButtonColors(
  ColorScheme scheme,
) {
  final isDark = scheme.brightness == Brightness.dark;
  final background = isDark ? Colors.white : Colors.black;
  final foreground = isDark ? Colors.black : Colors.white;
  return (background, foreground, background);
}

/// Google- und Apple-Buttons; Darstellung je nach [presentation].
class SocialSignInSection extends StatelessWidget {
  const SocialSignInSection({
    super.key,
    required this.busyProvider,
    required this.onGooglePressed,
    required this.onApplePressed,
    this.showDivider = true,
    this.presentation = SocialSignInPresentation.inline,
    this.appleLabel = 'Mit Apple fortfahren',
    this.googleLabel = 'Mit Google fortfahren',
    this.trailing,
  });

  static const double buttonHeight = 60;

  final SocialSignInProvider? busyProvider;
  final VoidCallback? onGooglePressed;
  final VoidCallback? onApplePressed;
  final bool showDivider;
  final SocialSignInPresentation presentation;
  final String appleLabel;
  final String googleLabel;
  final List<Widget>? trailing;

  static bool get isSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
  }

  static bool get isAppleSignInSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS;
  }

  bool get _useSquirclePanel => presentation == SocialSignInPresentation.startSheet;

  @override
  Widget build(BuildContext context) {
    if (!isSupported) {
      final trailingWidgets = trailing;
      if (presentation == SocialSignInPresentation.startSheet &&
          trailingWidgets != null &&
          trailingWidgets.isNotEmpty) {
        return LoginAuthSquirclePanel(
          socialButtons: const [],
          trailing: trailingWidgets,
        );
      }
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final appleForeground = loginAppleButtonColors(scheme).$2;

    final socialButtons = <Widget>[
      if (isAppleSignInSupported)
        LoginAuthOptionButton(
          label: appleLabel,
          variant: LoginAuthOptionButtonVariant.apple,
          compact: true,
          startScreenStyle: _useSquirclePanel,
          leading: Icon(
            LoginAuthIcons.apple,
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
        startScreenStyle: _useSquirclePanel,
        leading: const GoogleLogoIcon(size: 20),
        isLoading: busyProvider == SocialSignInProvider.google,
        onPressed: isGoogleSignInConfigured ? onGooglePressed : null,
      ),
    ];

    final panel = _useSquirclePanel
        ? LoginAuthSquirclePanel(
            socialButtons: socialButtons,
            trailing: trailing ?? const [],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...spacedWidgets(socialButtons, AppSpacing.m),
              if (trailing != null) ...[
                const SizedBox(height: AppSpacing.xl + AppSpacing.xs),
                ...trailing!,
              ],
            ],
          );

    if (!showDivider) return panel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OrDivider(showLabel: true),
        const SizedBox(height: AppSpacing.l),
        panel,
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.showLabel});

  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dividerColor = scheme.onSurfaceVariant.withValues(
      alpha: AppOpacity.subtle * 2.5,
    );

    return Row(
      children: [
        Expanded(child: Divider(color: dividerColor, height: 1)),
        if (showLabel)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: Text(
              'oder',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
                    fontSize: 12,
                  ),
            ),
          ),
        Expanded(child: Divider(color: dividerColor, height: 1)),
      ],
    );
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
          scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        ),
      _ when startScreenStyle => (
          scheme.surfaceContainerHighest,
          scheme.onSurface,
          scheme.surfaceContainerHighest,
        ),
      _ => (
          scheme.surfaceContainer,
          scheme.onSurface,
          scheme.surfaceContainerHighest.withValues(alpha: 0.6),
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
