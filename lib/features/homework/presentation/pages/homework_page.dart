import 'package:flutter/material.dart';

/// Platzhalter für den Bereich Hausaufgaben.
class HomeworkPage extends StatelessWidget {
  const HomeworkPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'work in progress.',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            _TodoListSketchIcon(
              color: textColor.withValues(alpha: 0.45),
              size: 52,
            ),
          ],
        ),
      ),
    );
  }
}

/// Kleines handgezeichnet wirkendes Todo-Listen-Symbol.
class _TodoListSketchIcon extends StatelessWidget {
  const _TodoListSketchIcon({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 1.15),
      painter: _TodoListSketchPainter(color: color),
    );
  }
}

class _TodoListSketchPainter extends CustomPainter {
  _TodoListSketchPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.045
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    _drawSketchPath(
      canvas,
      paint,
      [
        Offset(w * 0.12, h * 0.08),
        Offset(w * 0.9, h * 0.06),
        Offset(w * 0.92, h * 0.94),
        Offset(w * 0.1, h * 0.96),
        Offset(w * 0.08, h * 0.14),
      ],
      close: true,
    );

    const rowYs = [0.28, 0.5, 0.72];
    for (var i = 0; i < rowYs.length; i++) {
      final y = h * rowYs[i];
      _drawSketchPath(
        canvas,
        paint,
        [
          Offset(w * 0.2, y - h * 0.04),
          Offset(w * 0.28, y - h * 0.05),
          Offset(w * 0.29, y + h * 0.04),
          Offset(w * 0.21, y + h * 0.05),
          Offset(w * 0.19, y),
        ],
        close: true,
      );

      if (i == 0) {
        _drawSketchPath(
          canvas,
          paint,
          [
            Offset(w * 0.21, y + h * 0.01),
            Offset(w * 0.24, y + h * 0.04),
            Offset(w * 0.3, y - h * 0.03),
          ],
        );
      }

      final lineEnd = i == 2 ? w * 0.72 : w * 0.82;
      _drawSketchPath(
        canvas,
        paint,
        [
          Offset(w * 0.36, y + h * 0.01),
          Offset(w * 0.55, y - h * 0.01),
          Offset(lineEnd, y + h * 0.015),
        ],
      );
    }
  }

  void _drawSketchPath(
    Canvas canvas,
    Paint paint,
    List<Offset> points, {
    bool close = false,
  }) {
    if (points.length < 2) return;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final mid = Offset((prev.dx + curr.dx) / 2, (prev.dy + curr.dy) / 2);
      path.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
    }
    final last = points.last;
    path.lineTo(last.dx, last.dy);
    if (close) path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TodoListSketchPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
