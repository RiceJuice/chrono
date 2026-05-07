import 'package:flutter/material.dart';

class SettingsIsland extends StatelessWidget {
  const SettingsIsland({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            padding: const EdgeInsets.only(left: 58, right: 16),
            child: SizedBox(height: 1, child: ColoredBox(color: dividerColor)),
          ),
        );
      }
      dividedChildren.add(children[index]);
    }

    return dividedChildren;
  }
}
