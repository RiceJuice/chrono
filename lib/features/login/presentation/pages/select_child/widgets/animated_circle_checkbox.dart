import 'package:flutter/material.dart';

/// Kreisförmige Auswahl mit animierter Füllung und gezeichnetem Haken.
class AnimatedCircleCheckbox extends StatefulWidget {
  const AnimatedCircleCheckbox({
    super.key,
    required this.selected,
    this.onChanged,
    this.size = 24,
    this.enabled = true,
  });

  final bool selected;
  final ValueChanged<bool>? onChanged;
  final double size;
  final bool enabled;

  @override
  State<AnimatedCircleCheckbox> createState() => _AnimatedCircleCheckboxState();
}

class _AnimatedCircleCheckboxState extends State<AnimatedCircleCheckbox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fillAnimation;
  late final Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    _fillAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.6, curve: Curves.easeOutCubic),
    );
    _checkAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.28, 1, curve: Curves.easeOutCubic),
    );
    if (widget.selected) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(AnimatedCircleCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected == oldWidget.selected) return;
    if (widget.selected) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor = scheme.onSurface.withValues(alpha: 0.35);
    final fillColor = scheme.primary;
    final checkColor = scheme.onPrimary;

    return GestureDetector(
      onTap: widget.enabled && widget.onChanged != null
          ? () => widget.onChanged!(!widget.selected)
          : null,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _CircleCheckPainter(
                fillProgress: _fillAnimation.value,
                checkProgress: _checkAnimation.value,
                borderColor: borderColor,
                fillColor: fillColor,
                checkColor: checkColor,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CircleCheckPainter extends CustomPainter {
  _CircleCheckPainter({
    required this.fillProgress,
    required this.checkProgress,
    required this.borderColor,
    required this.fillColor,
    required this.checkColor,
  });

  final double fillProgress;
  final double checkProgress;
  final Color borderColor;
  final Color fillColor;
  final Color checkColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1.5;

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = Color.lerp(borderColor, fillColor, fillProgress) ?? borderColor;

    canvas.drawCircle(center, radius, borderPaint);

    if (fillProgress > 0) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.fill
          ..color = fillColor.withValues(alpha: fillProgress),
      );
    }

    if (checkProgress <= 0) return;

    final checkPath = Path()
      ..moveTo(size.width * 0.28, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.68)
      ..lineTo(size.width * 0.74, size.height * 0.34);

    final metrics = checkPath.computeMetrics().first;
    final drawPath = metrics.extractPath(0, metrics.length * checkProgress);

    final checkPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = checkColor.withValues(alpha: checkProgress);

    canvas.drawPath(drawPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant _CircleCheckPainter oldDelegate) {
    return oldDelegate.fillProgress != fillProgress ||
        oldDelegate.checkProgress != checkProgress ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.checkColor != checkColor;
  }
}
