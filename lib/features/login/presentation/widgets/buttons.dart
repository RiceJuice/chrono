import 'dart:async';

import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoginPrimaryButton extends StatelessWidget {
  const LoginPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.color,
    this.isLoading = false,
  });

  final String label;
  final FutureOr<void> Function()? onPressed;
  final Color color;
  final bool isLoading;

  static Future<void> _runWithOutcomeHaptic(FutureOr<void> Function()? fn) async {
    if (fn == null) return;
    try {
      final result = fn();
      if (result is Future<void>) {
        await result;
      }
      await HapticFeedback.successNotification();
    } catch (_) {
      await HapticFeedback.errorNotification();
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).elevatedButtonTheme.style!;
    final Color progressColor =
        color.computeLuminance() < 0.5 ? Colors.white : Colors.black87;
    return SizedBox(
      height: 60,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading || onPressed == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                unawaited(_runWithOutcomeHaptic(onPressed));
              },
        style: baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return color.withValues(alpha: AppOpacity.disabled);
            }
            return color;
          }),
        ),
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              )
            : Text(label),
      ),
    );
  }
}