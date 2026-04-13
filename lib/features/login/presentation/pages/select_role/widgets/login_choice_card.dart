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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 100,
        width: double.infinity,
        padding: AppInsets.cardPadding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.s),
          color: isSelected
              ? activeColor.withValues(alpha: AppOpacity.selectedFill)
              : Colors.white.withValues(alpha: AppOpacity.subtle),
          border: Border.all(
            color: isSelected
                ? activeColor.withValues(alpha: AppOpacity.selectedStroke)
                : Colors.white.withValues(alpha: AppOpacity.low),
          ),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Text(
            title,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontSize: 34,
            ),
          ),
        ),
      ),
    );
  }
}

