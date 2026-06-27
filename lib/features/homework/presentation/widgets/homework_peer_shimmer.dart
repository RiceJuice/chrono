import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:flutter/material.dart';

/// Dezenter grüner Puls für neue Klassen-Vorschläge.
class HomeworkPeerShimmer extends StatefulWidget {
  const HomeworkPeerShimmer({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<HomeworkPeerShimmer> createState() => _HomeworkPeerShimmerState();
}

class _HomeworkPeerShimmerState extends State<HomeworkPeerShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        final glow = Color.lerp(
          scheme.tertiary.withValues(alpha: 0.08),
          scheme.tertiary.withValues(alpha: 0.22),
          t,
        )!;

        return DecoratedBox(
          decoration: ShapeDecoration(
            color: scheme.tertiaryContainer.withValues(alpha: 0.18 + (0.1 * t)),
            shape: AppSquircle.shape(AppRadius.m),
            shadows: [
              BoxShadow(
                color: glow,
                blurRadius: 10 + (6 * t),
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
