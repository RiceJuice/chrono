import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/push/push_notification_service.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../routes/login_paths.dart';
import '../../widgets/buttons.dart';
import '../../widgets/login_flow_body.dart';
import '../../widgets/login_flow_spacing.dart';

/// Two deliberate steps: explain the benefit, then request native permission.
class LoginNotificationsPage extends StatefulWidget {
  const LoginNotificationsPage({
    super.key,
    this.requestStep = false,
    this.requestPermission,
  });

  final bool requestStep;
  final Future<void> Function()? requestPermission;

  @override
  State<LoginNotificationsPage> createState() => _LoginNotificationsPageState();
}

class _LoginNotificationsPageState extends State<LoginNotificationsPage> {
  bool _busy = false;

  Future<void> _enableNotifications() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final request = widget.requestPermission;
      if (request != null) {
        await request();
      } else if (PushNotificationService.supportsPush) {
        await PushNotificationService().syncTokenForCurrentUser(
          requestPermission: true,
        );
      }
      // Declining permission is also a valid completion of this optional step.
      if (mounted) context.go(LoginPaths.success);
    } catch (_) {
      if (!mounted) return;
      showAppToast(
        context,
        'Mitteilungen konnten gerade nicht aktiviert werden. Versuche es erneut oder fahre ohne fort.',
        kind: AppToastKind.error,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final compact = LoginFlowSpacing.isCompact(context);
    const accent = Color(0xFF0B4AA5);
    final requestStep = widget.requestStep;

    return LoginFlowBody(
      location: requestStep
          ? LoginPaths.notificationsPermission
          : LoginPaths.notificationsIntro,
      includeChrome: false,
      horizontalContentPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (requestStep)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: 'Zurück',
                      onPressed: _busy
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              context.go(LoginPaths.notificationsIntro);
                            },
                      icon: const Icon(CupertinoIcons.chevron_left, size: 22),
                    ),
                  ),
                _NotificationIllustration(
                  permission: requestStep,
                  accent: accent,
                ),
                SizedBox(height: compact ? 30 : 42),
                Text(
                  requestStep
                      ? 'Mitteilungen\nerlauben.'
                      : 'Wenn sich etwas\nändert, weißt du’s.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.libreBaskerville(
                    color: scheme.onSurface,
                    fontSize: LoginFlowSpacing.headerTitleSize(
                      context,
                      desktop: 36,
                    ),
                    fontWeight: FontWeight.w700,
                    height: 1.22,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  requestStep
                      ? 'Tippe auf „Mitteilungen erlauben“ und bestätige anschließend die Anfrage auf deinem Gerät.'
                      : 'Chorprobe verschoben? Konzert beginnt später? Wir würden dir gerne rechtzeitig Bescheid geben – mit einer Push-Mitteilung.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                    fontSize: 16,
                    height: 1.55,
                  ),
                ),
                SizedBox(height: compact ? 30 : 40),
                if (requestStep) ...[
                  LoginPrimaryButton(
                    label: 'Mitteilungen erlauben',
                    color: accent,
                    isLoading: _busy,
                    onPressed: _enableNotifications,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => context.go(LoginPaths.success),
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                    child: const Text('Vielleicht später'),
                  ),
                ] else ...[
                  Text(
                    'Dafür erlaubst du im nächsten Schritt Mitteilungen.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.5),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 26),
                  SizedBox.square(
                    dimension: 64,
                    child: IconButton.filled(
                      tooltip: 'Weiter zu Mitteilungen',
                      style: IconButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        shape: const CircleBorder(),
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.go(LoginPaths.notificationsPermission);
                      },
                      icon: const Icon(CupertinoIcons.arrow_right, size: 27),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationIllustration extends StatelessWidget {
  const _NotificationIllustration({
    required this.permission,
    required this.accent,
  });

  final bool permission;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 190,
      width: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 176,
            height: 176,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.055),
            ),
          ),
          Positioned(
            top: permission ? 38 : 12,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                permission
                    ? CupertinoIcons.bell
                    : CupertinoIcons.calendar,
                color: accent,
                size: 43,
              ),
            ),
          ),
          if (!permission)
            Positioned(
              bottom: 12,
              left: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: scheme.onSurface.withValues(alpha: 0.06),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        CupertinoIcons.music_note_2,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'CHRONO · BEISPIEL',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Chorprobe verschoben',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Heute geht’s um 16:30 Uhr los.',
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
