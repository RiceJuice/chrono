import 'package:flutter/material.dart';

class TuningForkIllustration extends StatelessWidget {
  const TuningForkIllustration({
    super.key,
    required this.size,
    this.color,
    this.isDark,
  });

  final double size;
  final Color? color;
  final bool? isDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolvedIsDark = isDark ?? scheme.brightness == Brightness.dark;
    final resolvedColor = color ?? scheme.onSurfaceVariant.withValues(
      alpha: resolvedIsDark ? 0.72 : 0.58,
    );

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TuningForkPainter(
          color: resolvedColor,
          isDark: resolvedIsDark,
        ),
      ),
    );
  }
}

class _TuningForkPainter extends CustomPainter {
  const _TuningForkPainter({
    required this.color,
    required this.isDark,
  });

  final Color color;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = w * 0.075;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: isDark ? 0.14 : 0.1)
      ..style = PaintingStyle.fill;

    final bodyPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final centerX = w * 0.5;
    final prongHalfGap = w * 0.085;
    final prongOuter = w * 0.19;
    final prongTop = h * 0.06;
    final prongCurveY = h * 0.56;
    final handleBottom = h * 0.92;

    final leftOuterX = centerX - prongHalfGap - prongOuter;
    final rightOuterX = centerX + prongHalfGap + prongOuter;
    final leftInnerX = centerX - prongHalfGap;
    final rightInnerX = centerX + prongHalfGap;

    final forkPath = Path()
      ..moveTo(leftOuterX, prongTop)
      ..lineTo(leftOuterX, prongCurveY - h * 0.08)
      ..quadraticBezierTo(
        leftOuterX,
        prongCurveY,
        leftInnerX,
        prongCurveY,
      )
      ..lineTo(leftInnerX, handleBottom - h * 0.08)
      ..quadraticBezierTo(
        centerX - w * 0.02,
        handleBottom,
        centerX,
        handleBottom,
      )
      ..quadraticBezierTo(
        centerX + w * 0.02,
        handleBottom,
        rightInnerX,
        handleBottom - h * 0.08,
      )
      ..lineTo(rightInnerX, prongCurveY)
      ..quadraticBezierTo(
        rightOuterX,
        prongCurveY,
        rightOuterX,
        prongCurveY - h * 0.08,
      )
      ..lineTo(rightOuterX, prongTop);

    final fillPath = Path()
      ..moveTo(leftOuterX - stroke * 0.35, prongTop)
      ..lineTo(leftOuterX - stroke * 0.35, prongCurveY - h * 0.06)
      ..quadraticBezierTo(
        leftOuterX - stroke * 0.35,
        prongCurveY + stroke * 0.2,
        leftInnerX - stroke * 0.15,
        prongCurveY + stroke * 0.2,
      )
      ..lineTo(leftInnerX - stroke * 0.15, handleBottom - h * 0.1)
      ..quadraticBezierTo(
        centerX - w * 0.04,
        handleBottom + stroke * 0.15,
        centerX,
        handleBottom + stroke * 0.15,
      )
      ..quadraticBezierTo(
        centerX + w * 0.04,
        handleBottom + stroke * 0.15,
        rightInnerX + stroke * 0.15,
        handleBottom - h * 0.1,
      )
      ..lineTo(rightInnerX + stroke * 0.15, prongCurveY + stroke * 0.2)
      ..quadraticBezierTo(
        rightOuterX + stroke * 0.35,
        prongCurveY + stroke * 0.2,
        rightOuterX + stroke * 0.35,
        prongCurveY - h * 0.06,
      )
      ..lineTo(rightOuterX + stroke * 0.35, prongTop)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(forkPath, bodyPaint);

    final prongCapPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(leftOuterX, prongTop), stroke * 0.42, prongCapPaint);
    canvas.drawCircle(Offset(rightOuterX, prongTop), stroke * 0.42, prongCapPaint);
  }

  @override
  bool shouldRepaint(covariant _TuningForkPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isDark != isDark;
  }
}
