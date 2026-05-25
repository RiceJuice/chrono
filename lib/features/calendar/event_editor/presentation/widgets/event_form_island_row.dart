import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:flutter/material.dart';

/// Zeile mit Label links und interaktivem Inhalt rechts (z. B. Datum/Uhrzeit-Pills).
class EventFormIslandRow extends StatelessWidget {
  const EventFormIslandRow({
    super.key,
    required this.label,
    required this.trailing,
  });

  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l,
        vertical: AppSpacing.m,
      ),
      child: Row(
        children: [
          Text(label, style: theme.textTheme.bodyLarge),
          const Spacer(),
          trailing,
        ],
      ),
    );
  }
}
