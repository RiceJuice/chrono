import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../routes/login_paths.dart';
import '../../widgets/login_flow_body.dart';
import '../../widgets/login_flow_spacing.dart';

/// Kurzer Abschlussbildschirm nach erfolgreichem Login / abgeschlossenem Onboarding.
class LoginSuccessPage extends StatefulWidget {
  const LoginSuccessPage({super.key});

  static const Duration displayDuration = Duration(milliseconds: 2200);

  @override
  State<LoginSuccessPage> createState() => _LoginSuccessPageState();
}

class _LoginSuccessPageState extends State<LoginSuccessPage> {
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();
    _redirectTimer = Timer(LoginSuccessPage.displayDuration, _goToCalendar);
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  void _goToCalendar() {
    if (!mounted) return;
    context.go('/calendar');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool compact = LoginFlowSpacing.isCompact(context);
    final double illustrationSize = compact ? 208 : 272;
    final double titleSize =
        LoginFlowSpacing.headerTitleSize(context, desktop: 42);
    final double subtitleSize = LoginFlowSpacing.headerSubtitleSize(context);

    return LoginFlowBody(
      location: LoginPaths.success,
      includeChrome: false,
      fillViewport: true,
      horizontalContentPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Align(
        alignment: const Alignment(0, -0.14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: illustrationSize,
                height: illustrationSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: illustrationSize * 0.82,
                      height: illustrationSize * 0.82,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.primary.withValues(alpha: 0.07),
                      ),
                    ),
                    Lottie.asset(
                      'assets/lottie/login_success.json',
                      width: illustrationSize,
                      height: illustrationSize,
                      repeat: false,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
              SizedBox(height: compact ? 14 : 18),
              Text(
                'Alles bereit!',
                textAlign: TextAlign.center,
                style: GoogleFonts.libreBaskerville(
                  color: scheme.onSurface,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: compact ? 6 : 8),
              Text(
                'Willkommen bei Chrono.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      fontSize: subtitleSize,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ) ??
                    TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      fontSize: subtitleSize,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
