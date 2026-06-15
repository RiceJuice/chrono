import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';

/// Abgerundete Insel für Login-Optionen (Squircle, vgl. Settings-Islands).
class LoginAuthSquirclePanel extends StatelessWidget {
  const LoginAuthSquirclePanel({
    super.key,
    required this.socialButtons,
    this.trailing = const [],
  });

  final List<Widget> socialButtons;
  final List<Widget> trailing;

  static const double _panelRadius = AppRadius.sheet;

  /// Innenabstand der Squircle-Box zum Bildschirmrand.
  static const double inset = AppSpacing.xl + AppSpacing.xs;

  /// Abstand zwischen Social-Gruppe und nachfolgenden Buttons (z. B. E-Mail).
  static const double groupGap = AppSpacing.xl + AppSpacing.xs;

  /// Abstand innerhalb der Social-Gruppe (Apple + Google).
  static const double socialGap = AppSpacing.m;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final double bottomPadding = bottomSafe + AppSpacing.l;

    final content = <Widget>[
      ..._withSpacing(socialButtons, socialGap),
      if (trailing.isNotEmpty) ...[
        const SizedBox(height: groupGap),
        ...trailing,
      ],
    ];

    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: scheme.surfaceContainer,
          shape: SmoothRectangleBorder(
            borderRadius: AppSquircle.topSheet(_panelRadius),
          ),
        ),
        child: ClipSmoothRect(
          radius: AppSquircle.topSheet(_panelRadius),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              inset,
              inset,
              inset,
              bottomPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: content,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _withSpacing(List<Widget> items, double gap) {
    if (items.isEmpty) return items;
    final spaced = <Widget>[items.first];
    for (var i = 1; i < items.length; i++) {
      spaced
        ..add(SizedBox(height: gap))
        ..add(items[i]);
    }
    return spaced;
  }
}
