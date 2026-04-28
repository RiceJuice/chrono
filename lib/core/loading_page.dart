import 'package:flutter/material.dart';

import 'theme/app_color_schemes.dart';

/// Erste Flutter-Oberfläche beim Start; Hintergrundfarbe entspricht dem nativen Splash.
/// [content] kann später durch ein animiertes Widget ersetzt werden (z. B. mit [AnimationController]).
class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key, this.content = const _LoadingLogo()});

  final Widget content;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColorSchemes.eventCardDark : AppColorSchemes.accent;
    return Scaffold(
      backgroundColor: background,
      body: Center(child: content),
    );
  }
}

class _LoadingLogo extends StatelessWidget {
  const _LoadingLogo();

  @override
  Widget build(BuildContext context) {
    // Animations-Hook: hier später z. B. FadeTransition / ScaleTransition.
    return Image.asset(
      'assets/icon/app_icon_foreground.png',
      width: 220,
      fit: BoxFit.contain,
    );
  }
}
