import 'package:flutter/material.dart';

/// A pulsing placeholder while image content is loading.
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({super.key});

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final minColor = Color.alphaBlend(
      colorScheme.onSurface.withOpacity(0.060),
      colorScheme.surfaceContainerHighest,
    );
    final maxColor = Color.alphaBlend(
      colorScheme.onSurface.withOpacity(0.151),
      colorScheme.surfaceContainerHighest,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Frame-by-frame interpolation via ticker (typically ~60fps on 60Hz).
        final t = Curves.easeInOutSine.transform(_controller.value);
        return ColoredBox(
          color: Color.lerp(minColor, maxColor, t) ?? minColor,
        );
      },
    );
  }
}
