import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/auth_repository.dart';
import '../../data/social_auth_service.dart';
import '../providers/auth_repository_provider.dart';
import '../providers/profile_gate_provider.dart';
import '../routes/login_paths.dart';
import 'social_sign_in_section.dart';

/// Social-Login mit Auth-Logik für Start- und Credentials-Screen.
class LoginSocialSignInBlock extends ConsumerStatefulWidget {
  const LoginSocialSignInBlock({
    super.key,
    this.disabled = false,
    this.onBusyChanged,
    this.showDivider = true,
    this.presentation = SocialSignInPresentation.inline,
    this.trailing,
  });

  final bool disabled;
  final ValueChanged<bool>? onBusyChanged;
  final bool showDivider;
  final SocialSignInPresentation presentation;
  final List<Widget>? trailing;

  @override
  ConsumerState<LoginSocialSignInBlock> createState() =>
      _LoginSocialSignInBlockState();
}

class _LoginSocialSignInBlockState extends ConsumerState<LoginSocialSignInBlock> {
  SocialSignInProvider? _busy;

  Future<void> _showError(String message) async {
    if (!mounted) return;
    showAppToast(context, message, kind: AppToastKind.error);
  }

  Future<void> _completeSocialSignIn() async {
    await ref.read(profileGateProvider).refresh();
    if (!mounted) return;
    final target =
        ref.read(profileGateProvider).requiredPath ?? LoginPaths.success;
    context.go(target);
  }

  Future<void> _runSocialSignIn(
    SocialSignInProvider provider,
    Future<void> Function() signIn,
  ) async {
    if (widget.disabled || _busy != null) return;
    setState(() => _busy = provider);
    widget.onBusyChanged?.call(true);
    try {
      await signIn();
      if (!mounted) return;
      await _completeSocialSignIn();
    } on AuthSignInCancelledException {
      // Nutzer hat abgebrochen.
    } on AuthRepositoryException catch (e) {
      await _showError(e.message);
    } catch (_) {
      await _showError('Anmeldung fehlgeschlagen. Bitte versuche es erneut.');
    } finally {
      if (mounted) {
        setState(() => _busy = null);
        widget.onBusyChanged?.call(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!SocialSignInSection.isSupported) {
      final trailing = widget.trailing;
      if (widget.presentation == SocialSignInPresentation.startSheet &&
          trailing != null &&
          trailing.isNotEmpty) {
        return SocialSignInSection(
          showDivider: widget.showDivider,
          presentation: widget.presentation,
          trailing: trailing,
          busyProvider: null,
          onGooglePressed: null,
          onApplePressed: null,
        );
      }
      return const SizedBox.shrink();
    }

    final disabled = widget.disabled || _busy != null;

    return SocialSignInSection(
      showDivider: widget.showDivider,
      presentation: widget.presentation,
      trailing: widget.trailing,
      busyProvider: _busy,
      onGooglePressed: disabled
          ? null
          : () => _runSocialSignIn(
                SocialSignInProvider.google,
                () => ref.read(authRepositoryProvider).signInWithGoogle(),
              ),
      onApplePressed: disabled
          ? null
          : () => _runSocialSignIn(
                SocialSignInProvider.apple,
                () => ref.read(authRepositoryProvider).signInWithApple(),
              ),
    );
  }
}
