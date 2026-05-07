import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

class SettingsSliverHeader extends StatelessWidget {
  const SettingsSliverHeader({super.key});

  static const largeTitle = 'Einstellungen und \nPräferenzen';
  static const compactTitle = 'Einstellungen & Präferenzen';

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SettingsSliverHeaderDelegate(topPadding: topPadding),
    );
  }
}

class _SettingsSliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _SettingsSliverHeaderDelegate({required this.topPadding});

  final double topPadding;

  @override
  double get minExtent => topPadding + 50;

  @override
  double get maxExtent => topPadding + 120;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final largeOpacity = (1 - progress * 1.35).clamp(0.0, 1.0);
    final compactOpacity = ((progress - 0.18) / 0.45).clamp(0.0, 1.0);
    final largeTop = lerpDouble(topPadding + 40, topPadding + 12, progress)!;

    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 16,
            right: 16,
            top: largeTop,
            child: Opacity(
              opacity: largeOpacity,
              child: Text(
                SettingsSliverHeader.largeTitle,
                maxLines: 2,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: topPadding + 8,
            child: Opacity(
              opacity: compactOpacity,
              child: Text(
                SettingsSliverHeader.compactTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_SettingsSliverHeaderDelegate oldDelegate) {
    return oldDelegate.topPadding != topPadding;
  }
}
