import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/features/homework/domain/models/homework_fragment.dart';
import 'package:flutter/material.dart';

Color homeworkChipBackground(ColorScheme scheme, String chipColorKey) {
  return switch (chipColorKey) {
    'book' => scheme.primaryContainer,
    'worksheet' => scheme.secondaryContainer,
    'notebook' => scheme.tertiaryContainer,
    'online' => scheme.surfaceContainerHighest,
    'format' => scheme.surfaceContainerHigh,
    'separator' => scheme.surfaceContainerHighest,
    _ => scheme.surfaceContainerHighest,
  };
}

Color homeworkChipForeground(ColorScheme scheme, String chipColorKey) {
  return switch (chipColorKey) {
    'book' => scheme.onPrimaryContainer,
    'worksheet' => scheme.onSecondaryContainer,
    'notebook' => scheme.onTertiaryContainer,
    _ => scheme.onSurface,
  };
}

class HomeworkFragmentChip extends StatelessWidget {
  const HomeworkFragmentChip({
    super.key,
    required this.fragment,
    this.compact = false,
  });

  final HomeworkFragment fragment;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = homeworkChipBackground(scheme, fragment.chipColorKey);
    final fg = homeworkChipForeground(scheme, fragment.chipColorKey);

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: bg,
        shape: AppSquircle.shape(compact ? AppRadius.s : AppRadius.m),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.s : AppSpacing.m,
          vertical: compact ? 2 : AppSpacing.xs,
        ),
        child: Text(
          fragment.displayText,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class HomeworkFragmentChipRow extends StatelessWidget {
  const HomeworkFragmentChipRow({
    super.key,
    required this.fragments,
    this.compact = false,
  });

  final List<HomeworkFragment> fragments;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (fragments.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpacing.s,
      runSpacing: AppSpacing.s,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final fragment in fragments)
          HomeworkFragmentChip(fragment: fragment, compact: compact),
      ],
    );
  }
}
