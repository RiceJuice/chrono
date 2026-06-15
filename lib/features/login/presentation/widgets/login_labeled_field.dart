import 'package:flutter/material.dart';

import 'login_flow_spacing.dart';

TextStyle loginFieldLabelStyle(BuildContext context) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  return theme.textTheme.labelLarge?.copyWith(
        color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ) ??
      TextStyle(
        color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
        fontWeight: FontWeight.w500,
        fontSize: 13,
      );
}

class LoginLabeledField extends StatelessWidget {
  const LoginLabeledField({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: loginFieldLabelStyle(context)),
        SizedBox(height: LoginFlowSpacing.gapAfterFieldLabel(context)),
        child,
      ],
    );
  }
}
