import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:flutter/material.dart';

/// Gruppierte Formular-Zeilen mit [surfaceContainerHigh] (Event-Editor).
class EventFormIsland extends StatelessWidget {
  const EventFormIsland({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.l),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _withDividers(context),
        ),
      ),
    );
  }

  List<Widget> _withDividers(BuildContext context) {
    final dividerColor = Theme.of(
      context,
    ).colorScheme.outlineVariant.withValues(alpha: 0.22);
    final dividedChildren = <Widget>[];

    for (var index = 0; index < children.length; index++) {
      if (index > 0) {
        dividedChildren.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
            child: SizedBox(height: 1, child: ColoredBox(color: dividerColor)),
          ),
        );
      }
      dividedChildren.add(children[index]);
    }

    return dividedChildren;
  }
}
