import 'package:flutter/material.dart';
import 'package:figma_squircle/figma_squircle.dart';

import '../../../../core/theme/theme_tokens.dart';

class SettingsIsland extends StatelessWidget {
  const SettingsIsland({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: scheme.surfaceContainerHigh,
        shape: AppSquircle.shape(AppRadius.l),
      ),
      child: ClipSmoothRect(
        radius: AppSquircle.borderRadius(AppRadius.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}
