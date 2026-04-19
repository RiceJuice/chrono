import 'dart:async';

import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/auth_repository.dart';
import '../../../domain/models/login_flow_step.dart';
import '../../providers/auth_repository_provider.dart';
import '../../providers/login_step_scaffold.dart';
import '../../providers/profile_gate_provider.dart';
import '../../routes/login_routes.dart';
import '../../state/login_flow_draft.dart';
import '../credentials/credentials_page.dart';

class EmailConfirmationPage extends ConsumerStatefulWidget {
  const EmailConfirmationPage({super.key});

  @override
  ConsumerState<EmailConfirmationPage> createState() =>
      _EmailConfirmationPageState();
}

class _EmailConfirmationPageState extends ConsumerState<EmailConfirmationPage>
    with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 5);

  Timer? _pollTimer;
  bool _advancing = false;
  bool _resendBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      unawaited(_runAdvanceCheck());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_runAdvanceCheck());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_runAdvanceCheck());
    }
  }

  Future<void> _showMessage(
    String message, {
    AppToastKind kind = AppToastKind.info,
  }) async {
    if (!mounted) return;
    showAppToast(context, message, kind: kind);
  }

  Future<void> _runAdvanceCheck() async {
    if (!mounted || _advancing) return;
    _advancing = true;
    try {
      final repo = ref.read(authRepositoryProvider);
      final draft = LoginFlowDraft.instance;

      final advanced = await repo.tryAdvanceAfterEmailConfirmation(
        email: draft.email,
        password: draft.password,
      );
      if (!advanced || !mounted) return;

      await ref.read(profileGateProvider).refresh();
      if (!mounted) return;
      final target =
          ref.read(profileGateProvider).requiredPath ?? LoginPaths.role;
      context.go(target);
    } on AuthRepositoryException catch (e) {
      if (!mounted) return;
      debugPrint('E-Mail-Bestätigung (Hintergrund): ${e.message}');
    } catch (_) {
      if (!mounted) return;
      debugPrint('E-Mail-Bestätigung (Hintergrund): unbekannter Fehler');
    } finally {
      _advancing = false;
    }
  }

  Future<void> _openMailApp() async {
    final uri = Uri.parse('mailto:');
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        await _showMessage(
          'Die E-Mail-App konnte nicht geöffnet werden.',
          kind: AppToastKind.error,
        );
      }
    } catch (_) {
      if (mounted) {
        await _showMessage(
          'Die E-Mail-App konnte nicht geöffnet werden.',
          kind: AppToastKind.error,
        );
      }
    }
  }

  Future<void> _resendEmail() async {
    setState(() => _resendBusy = true);
    try {
      final draft = LoginFlowDraft.instance;
      final repo = ref.read(authRepositoryProvider);
      final sessionUserEmail = repo.currentUserEmail;
      final targetEmail = draft.email.trim().isNotEmpty
          ? draft.email
          : (sessionUserEmail ?? '');
      await repo.resendConfirmationEmail(email: targetEmail);
      await _showMessage(
        'Bestätigungs-E-Mail wurde erneut gesendet.',
        kind: AppToastKind.success,
      );
    } on AuthRepositoryException catch (e) {
      await _showMessage(e.message, kind: AppToastKind.error);
    } catch (_) {
      await _showMessage(
        'Bestätigungs-E-Mail konnte nicht erneut gesendet werden.',
        kind: AppToastKind.error,
      );
    } finally {
      if (mounted) setState(() => _resendBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final double screenH = MediaQuery.sizeOf(context).height;
    final double footerLead = (screenH * 0.055).clamp(20.0, 52.0);
    final double footerTail = (screenH * 0.022).clamp(10.0, 22.0);
    final double topGap = (screenH * 0.028).clamp(6.0, 24.0);
    final double iconBodyGap = (screenH * 0.02).clamp(12.0, 20.0);
    final double headingBodyGap = (screenH * 0.012).clamp(8.0, 14.0);
    final draftEmail = LoginFlowDraft.instance.email.trim();
    final repoEmail = ref.read(authRepositoryProvider).currentUserEmail;
    final email = draftEmail.isNotEmpty
        ? draftEmail
        : (repoEmail?.trim().isNotEmpty == true
              ? repoEmail!.trim()
              : 'deine E-Mail-Adresse');

    final emailHighlightStyle =
        theme.textTheme.bodyLarge?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: scheme.primary,
          height: 1.5,
          fontSize: 17,
        ) ??
        TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: scheme.primary,
          fontSize: 17,
          height: 1.5,
        );

    // titleMedium ist im App-Theme ohne Libre Baskerville (s. AppTextThemes).
    final subheadingStyle =
        theme.textTheme.titleMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 22,
          height: 1.3,
        ) ??
        TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
          height: 1.3,
          fontSize: 22,
        );

    final bodyStyle =
        theme.textTheme.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant,
          height: 1.5,
          fontSize: 17,
        ) ??
        TextStyle(
          color: scheme.onSurfaceVariant,
          height: 1.5,
          fontSize: 17,
        );

    final footerMutedStyle =
        theme.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
          fontSize: 15,
          height: 1.45,
        ) ??
        TextStyle(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
          height: 1.45,
          fontSize: 15,
        );

    final linkStyle = footerMutedStyle.copyWith(
      color: scheme.primary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: scheme.primary,
    );

    return LoginStepScaffold(
      step: LoginFlowStep.credentials,
      titleOverride: 'E-Mail bestätigen',
      plainTitleFont: true,
      showPrimaryButton: true,
      submitLabel: 'E-Mail-App öffnen',
      nextPath: LoginPaths.role,
      centerChildInScrollViewport: true,
      contentMaxWidth: CredentialsPage.maxFormWidth,
      primaryButtonMaxWidth: CredentialsPage.maxFormWidth,
      footerLeadHeight: footerLead,
      footerTailHeight: footerTail,
      onAsyncProceed: (_) async {
        await _openMailApp();
      },
      footer: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: CredentialsPage.maxFormWidth,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text.rich(
              TextSpan(
                style: footerMutedStyle,
                children: [
                  const TextSpan(text: 'Keine E-Mail gefunden? '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: _resendBusy
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.primary,
                            ),
                          )
                        : GestureDetector(
                            onTap: () => unawaited(_resendEmail()),
                            child: Text('Erneut senden', style: linkStyle),
                          ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: topGap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.mail_rounded,
              size: 96,
              color: scheme.primary,
            ),
            SizedBox(height: iconBodyGap),
            SizedBox(
              width: double.infinity,
              child: Text(
                'Prüfe dein E-Mail-Postfach',
                style: subheadingStyle,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: headingBodyGap),
            SizedBox(
              width: double.infinity,
              child: Text.rich(
                TextSpan(
                  style: bodyStyle,
                  children: [
                    const TextSpan(
                      text: 'Wir haben eine Bestätigungs-E-Mail an ',
                    ),
                    TextSpan(text: email, style: emailHighlightStyle),
                    const TextSpan(
                      text:
                          ' geschickt. Tippe in der Nachricht auf den Link. '
                          'Sobald du bestätigt hast, geht es hier automatisch weiter – '
                          'du musst nichts weiter tun.',
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
