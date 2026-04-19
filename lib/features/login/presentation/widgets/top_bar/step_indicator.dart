import 'package:flutter/material.dart';

class LoginStepIndicator extends StatelessWidget {
  const LoginStepIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 4,
    this.width = 50,
  });

  final int currentStep;
  final int totalSteps;
  final double width;

  @override
  Widget build(BuildContext context) {
    final Color inactive = Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: 0.20);
    return Row(
      children: List.generate(totalSteps * 2 - 1, (index) {
        if (index.isOdd) {
          return const SizedBox(width: 20);
        }

        final step = (index ~/ 2) + 1;
        final isActive = step == currentStep;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 4,
          width: width,
          decoration: BoxDecoration(
            color: isActive ? _stepColor(step) : inactive,
            borderRadius: BorderRadius.circular(100),
          ),
        );
      }),
    );
  }

  Color _stepColor(int step) {
    return switch (step) {
      1 => const Color(0xFFCBBBA0),
      2 => const Color(0xFF0B5A38),
      3 => const Color(0xFFB33B0B),
      _ => const Color(0xFF0B4AA5),
    };
  }
}
