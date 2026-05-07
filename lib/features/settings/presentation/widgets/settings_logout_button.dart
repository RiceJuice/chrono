import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.logout_rounded, size: 19),
        label: const Text('Abmelden'),
        onPressed: () async {
          HapticFeedback.mediumImpact();
          await onPressed();
        },
      ),
    );
  }
}
