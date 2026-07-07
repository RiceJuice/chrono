import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Auswahl, ob Essensbilder im Kalender angezeigt werden — mit KI-Hinweis.
class LoginMealImagesPreferenceBox extends StatelessWidget {
  const LoginMealImagesPreferenceBox({
    super.key,
    required this.showMealImages,
    required this.onChanged,
  });

  final bool showMealImages;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.9),
        ),
        color: scheme.surfaceContainerLow,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Essensbilder anzeigen',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Switch.adaptive(
                  value: showMealImages,
                  onChanged: onChanged,
                ),
              ],
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: scheme.errorContainer.withValues(alpha: 0.45),
                border: Border.all(
                  color: scheme.error.withValues(alpha: 0.35),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PhosphorIcon(
                      PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
                      size: 22,
                      color: scheme.error,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Die Essensbilder sind KI-generiert. Sie entsprechen '
                        'nicht der Realität und dürfen nicht als Erwartung an '
                        'das tatsächliche Essen herangezogen werden.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              showMealImages
                  ? 'Bilder werden im Speiseplan angezeigt.'
                  : 'Bilder werden im Speiseplan ausgeblendet.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
