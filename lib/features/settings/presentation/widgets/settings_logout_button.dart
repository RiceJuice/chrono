import 'package:chronoapp/features/settings/presentation/helpers/settings_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/theme_tokens.dart';

class SettingsLogoutButton extends StatelessWidget {
  const SettingsLogoutButton({super.key, required this.onPressed});

  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.surfaceContainerHigh,
          foregroundColor: scheme.error,
          minimumSize: const Size.fromHeight(54),
          shape: AppSquircle.shape(AppRadius.l),
        ),
        icon: PhosphorIcon(SettingsIcons.logout, size: 20),
        label: const Text('Abmelden'),
        onPressed: () async {
          HapticFeedback.mediumImpact();
          await onPressed();
        },
      ),
    );
  }
}
