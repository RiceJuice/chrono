import 'dart:math' as math;

import 'package:flutter/material.dart';

class TuningForkModel extends StatelessWidget {
  const TuningForkModel({super.key, required this.strike});

  final Animation<double> strike;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _ForkPainter(
          strike: strike,
          isDark: Theme.of(context).brightness == Brightness.dark,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ForkPainter extends CustomPainter {
  _ForkPainter({required this.strike, required this.isDark})
    : super(repaint: strike);

  final Animation<double> strike;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 220, size.height / 250);
    final t = strike.value;
    final bend = 3.4 * math.sin(t * math.pi * 26) * math.exp(-5 * t) * (1 - t);
    final silhouette = _silhouette(bend);

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    canvas.rotate(0.14);
    canvas.translate(-110, -125);

    canvas.drawPath(
      silhouette.shift(const Offset(8, 12)),
      Paint()
        ..color = const Color(0xFF111C28).withValues(alpha: isDark ? 0.6 : 0.24)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    final depth = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF838F9F), Color(0xFF394654), Color(0xFF667381)],
      ).createShader(const Rect.fromLTWH(70, 17, 80, 216));
    // Layer the same profile to give the polished face a continuous sidewall.
    for (var step = 9; step > 0; step--) {
      canvas.drawPath(
        silhouette.shift(Offset(step * 0.63, step * 0.32)),
        depth,
      );
    }

    canvas.drawPath(
      silhouette,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment(-0.92, -0.35),
          end: Alignment(0.92, 0.35),
          colors: [
            Color(0xFF82909F),
            Color(0xFFEAF1F7),
            Color(0xFFB5C1CD),
            Color(0xFFF8FBFC),
            Color(0xFF93A1AF),
            Color(0xFFC9D3DB),
          ],
          stops: [0, 0.19, 0.43, 0.57, 0.83, 1],
        ).createShader(const Rect.fromLTWH(67, 17, 86, 215)),
    );
    canvas.drawPath(
      silhouette,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.85
        ..color = const Color(0xFFEDF4FA).withValues(alpha: 0.9),
    );

    final highlight = Path()
      ..moveTo(71 - bend, 25)
      ..quadraticBezierTo(71 - bend * 0.45, 76, 71, 111)
      ..quadraticBezierTo(71, 137, 91, 149)
      ..moveTo(131 + bend, 25)
      ..quadraticBezierTo(131 + bend * 0.45, 78, 131, 111)
      ..moveTo(104, 160)
      ..lineTo(104, 214);
    canvas.drawPath(
      highlight,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFF7FAFE).withValues(alpha: 0.68),
    );
    canvas.restore();
  }

  Path _silhouette(double bend) {
    return Path()
      ..moveTo(74 - bend, 17)
      ..lineTo(88 - bend, 17)
      ..quadraticBezierTo(93 - bend, 17, 93 - bend, 23)
      ..cubicTo(93 - bend, 58, 93, 91, 93, 109)
      ..cubicTo(93, 123, 99, 133, 110, 133)
      ..cubicTo(121, 133, 127, 123, 127, 109)
      ..cubicTo(127, 91, 127 + bend, 58, 127 + bend, 23)
      ..quadraticBezierTo(127 + bend, 17, 132 + bend, 17)
      ..lineTo(146 + bend, 17)
      ..quadraticBezierTo(152 + bend, 17, 152 + bend, 23)
      ..cubicTo(152 + bend, 59, 152, 89, 152, 110)
      ..cubicTo(152, 134, 139, 151, 120, 156)
      ..lineTo(120, 216)
      ..quadraticBezierTo(120, 220, 125, 223)
      ..quadraticBezierTo(127, 224, 127, 228)
      ..quadraticBezierTo(127, 233, 122, 233)
      ..lineTo(98, 233)
      ..quadraticBezierTo(93, 233, 93, 228)
      ..quadraticBezierTo(93, 224, 95, 223)
      ..quadraticBezierTo(100, 220, 100, 216)
      ..lineTo(100, 156)
      ..cubicTo(81, 151, 68, 134, 68, 110)
      ..cubicTo(68, 89, 68 - bend, 59, 68 - bend, 23)
      ..quadraticBezierTo(68 - bend, 17, 74 - bend, 17)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _ForkPainter oldDelegate) =>
      oldDelegate.strike != strike || oldDelegate.isDark != isDark;
}
