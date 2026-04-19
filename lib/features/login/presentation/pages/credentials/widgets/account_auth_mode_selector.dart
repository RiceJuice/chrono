import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'account_auth_mode.dart';

class AccountAuthModeSelector extends StatelessWidget {
  const AccountAuthModeSelector({
    super.key,
    required this.selectedMode,
    required this.onChanged,
  });

  final AccountAuthMode selectedMode;
  final ValueChanged<AccountAuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final isSignIn = selectedMode == AccountAuthMode.signIn;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Text.rich(
      TextSpan(
        text: isSignIn ? 'Noch keinen Account? ' : 'Bereits registriert? ',
        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
        children: [
          TextSpan(
            text: isSignIn ? 'Hier registrieren' : 'Jetzt anmelden',
            style: TextStyle(
              color: scheme.primary,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                HapticFeedback.selectionClick();
                onChanged(
                  isSignIn ? AccountAuthMode.signUp : AccountAuthMode.signIn,
                );
              },
          ),
        ],
      ),
    );
  }
}