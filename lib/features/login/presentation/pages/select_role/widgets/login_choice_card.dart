import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoginChoiceCard extends StatelessWidget {
  const LoginChoiceCard({
    super.key,
    required this.title,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 120,
        width: double.infinity,
        padding: AppInsets.cardPadding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.s),
          color: isSelected
              ? activeColor
              : scheme.surfaceContainerHighest,
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Text(
            title,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: isSelected
                  ? (activeColor.computeLuminance() > 0.55
                      ? scheme.onSurface
                      : Colors.white)
                  : scheme.onSurface,
              fontSize: 34,
            ),
          ),
        ),
      ),
    );
  }
}

