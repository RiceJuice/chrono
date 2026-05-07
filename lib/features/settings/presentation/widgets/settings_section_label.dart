import 'package:flutter/material.dart';

class SettingsSectionLabel extends StatelessWidget {
  const SettingsSectionLabel({super.key, required this.title, this.top = 22});

  final String title;
  final double top;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(0, top, 0, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
