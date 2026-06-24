import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../../data/auth_repository.dart';
import '../../providers/auth_repository_provider.dart';
import '../../providers/profile_gate_provider.dart';
import '../../routes/login_paths.dart';
import '../../widgets/login_flow_body.dart';
import '../../widgets/login_flow_spacing.dart';

/// Kurzer Abschlussbildschirm nach erfolgreichem Login / abgeschlossenem Onboarding.
class LoginSuccessPage extends ConsumerStatefulWidget {
  const LoginSuccessPage({super.key});

  static const Duration displayDuration = Duration(milliseconds: 2200);

  @override
  ConsumerState<LoginSuccessPage> createState() => _LoginSuccessPageState();
}

class _LoginSuccessPageState extends ConsumerState<LoginSuccessPage> {
  Timer? _redirectTimer;
  bool _completing = true;
  bool _completed = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_completeOnboarding());
    });
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    setState(() {
      _completing = true;
      _errorMessage = null;
    });

    try {
      final activeChildId = ref.read(profileGateProvider).data.activeChildId;
      await ref.read(authRepositoryProvider).completeOnboarding(
            activeChildId: activeChildId,
          );
      await ref.read(profileGateProvider).refresh();
      if (!mounted) return;
      setState(() {
        _completing = false;
        _completed = true;
      });
      _redirectTimer = Timer(LoginSuccessPage.displayDuration, _goToCalendar);
    } on AuthRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _completing = false;
        _completed = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _completing = false;
        _completed = false;
        _errorMessage =
            'Onboarding konnte nicht abgeschlossen werden. Bitte erneut versuchen.';
      });
    }
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
                    if (_completing)
                      SizedBox(
                        width: illustrationSize * 0.35,
                        height: illustrationSize * 0.35,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: scheme.primary,
                        ),
                      )
                    else if (_completed)
                      Lottie.asset(
                        'assets/lottie/login_success.json',
                        width: illustrationSize,
                        height: illustrationSize,
                        repeat: false,
                        fit: BoxFit.contain,
                      )
                    else
                      Icon(
                        Icons.error_outline_rounded,
                        size: illustrationSize * 0.35,
                        color: scheme.error,
                      ),
                  ],
                ),
              ),
              SizedBox(height: compact ? 14 : 18),
              Text(
                _completing
                    ? 'Wird abgeschlossen …'
                    : _completed
                        ? 'Alles bereit!'
                        : 'Fast geschafft',
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
                _errorMessage ??
                    (_completing
                        ? 'Dein Profil wird gespeichert.'
                        : 'Willkommen bei Chrono.'),
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
              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _completing ? null : () => unawaited(_completeOnboarding()),
                  child: const Text('Erneut versuchen'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
