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
    final resolvedColor = color ??
        scheme.onSurfaceVariant.withValues(
          alpha: resolvedIsDark ? 0.72 : 0.58,
        );

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TuningForkPainter(
          accentColor: resolvedColor,
          isDark: resolvedIsDark,
        ),
      ),
    );
  }
}

class _TuningForkPainter extends CustomPainter {
  const _TuningForkPainter({
    required this.accentColor,
    required this.isDark,
  });

  final Color accentColor;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final metalLight = Color.lerp(
      const Color(0xFFD8DCE3),
      accentColor,
      isDark ? 0.35 : 0.15,
    )!;
    final metalMid = Color.lerp(
      const Color(0xFFA8ADB6),
      accentColor,
      isDark ? 0.45 : 0.25,
    )!;
    final metalDark = Color.lerp(
      const Color(0xFF7A808A),
      accentColor,
      isDark ? 0.55 : 0.35,
    )!;

    final prongWidth = w * 0.11;
    final prongGap = w * 0.1;
    final centerX = w * 0.5;
    final leftProngLeft = centerX - prongGap / 2 - prongWidth;
    final rightProngLeft = centerX + prongGap / 2;
    final prongTop = h * 0.02;
    final prongBottom = h * 0.44;
    final jointBottom = h * 0.5;
    final stemWidth = w * 0.1;
    final stemLeft = centerX - stemWidth / 2;
    final stemTop = jointBottom;
    final stemBottom = h * 0.76;
    final baseBottom = h * 0.98;

    _drawAmbientShadow(
      canvas: canvas,
      centerX: centerX,
      centerY: h * 0.54,
      width: w * 0.78,
      height: h * 0.88,
    );
    _drawGroundShadow(
      canvas: canvas,
      centerX: centerX,
      groundY: baseBottom + h * 0.008,
      width: w * 0.5,
      height: h * 0.09,
    );
    _drawContactShadow(
      canvas: canvas,
      centerX: centerX,
      groundY: baseBottom - h * 0.005,
      width: w * 0.22,
      height: h * 0.035,
    );

    _drawProng(
      canvas: canvas,
      left: leftProngLeft,
      top: prongTop,
      width: prongWidth,
      height: prongBottom - prongTop,
      metalLight: metalLight,
      metalMid: metalMid,
      metalDark: metalDark,
    );
    _drawProng(
      canvas: canvas,
      left: rightProngLeft,
      top: prongTop,
      width: prongWidth,
      height: prongBottom - prongTop,
      metalLight: metalLight,
      metalMid: metalMid,
      metalDark: metalDark,
    );

    _drawUJoint(
      canvas: canvas,
      centerX: centerX,
      prongGap: prongGap,
      prongWidth: prongWidth,
      leftProngLeft: leftProngLeft,
      rightProngLeft: rightProngLeft,
      prongBottom: prongBottom,
      jointBottom: jointBottom,
      metalLight: metalLight,
      metalMid: metalMid,
      metalDark: metalDark,
    );

    _drawStem(
      canvas: canvas,
      left: stemLeft,
      top: stemTop,
      width: stemWidth,
      height: stemBottom - stemTop,
      metalLight: metalLight,
      metalMid: metalMid,
      metalDark: metalDark,
    );

    _drawBase(
      canvas: canvas,
      centerX: centerX,
      top: stemBottom,
      bottom: baseBottom,
      maxWidth: w * 0.2,
    );
  }

  void _drawAmbientShadow({
    required Canvas canvas,
    required double centerX,
    required double centerY,
    required double width,
    required double height,
  }) {
    final rect = Rect.fromCenter(
      center: Offset(centerX + width * 0.07, centerY + height * 0.08),
      width: width,
      height: height,
    );
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.68,
        colors: [
          Colors.black.withValues(alpha: isDark ? 0.58 : 0.38),
          Colors.black.withValues(alpha: isDark ? 0.32 : 0.2),
          Colors.black.withValues(alpha: isDark ? 0.12 : 0.07),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.65, 1.0],
      ).createShader(rect);
    canvas.drawOval(rect, paint);
  }

  void _drawGroundShadow({
    required Canvas canvas,
    required double centerX,
    required double groundY,
    required double width,
    required double height,
  }) {
    final rect = Rect.fromCenter(
      center: Offset(centerX + width * 0.1, groundY),
      width: width,
      height: height,
    );
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.9,
        colors: [
          Colors.black.withValues(alpha: isDark ? 0.72 : 0.52),
          Colors.black.withValues(alpha: isDark ? 0.38 : 0.26),
          Colors.black.withValues(alpha: isDark ? 0.14 : 0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.32, 0.62, 1.0],
      ).createShader(rect);
    canvas.drawOval(rect, paint);
  }

  void _drawContactShadow({
    required Canvas canvas,
    required double centerX,
    required double groundY,
    required double width,
    required double height,
  }) {
    final rect = Rect.fromCenter(
      center: Offset(centerX + width * 0.12, groundY),
      width: width,
      height: height,
    );
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.75,
        colors: [
          Colors.black.withValues(alpha: isDark ? 0.85 : 0.68),
          Colors.black.withValues(alpha: isDark ? 0.45 : 0.32),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);
    canvas.drawOval(rect, paint);
  }

  void _drawProng({
    required Canvas canvas,
    required double left,
    required double top,
    required double width,
    required double height,
    required Color metalLight,
    required Color metalMid,
    required Color metalDark,
  }) {
    final rect = Rect.fromLTWH(left, top, width, height);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [metalLight, metalMid, metalDark],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.12 : 0.22)
      ..strokeWidth = width * 0.06;
    canvas.drawLine(
      Offset(left + width * 0.18, top + height * 0.04),
      Offset(left + width * 0.18, top + height * 0.96),
      highlight,
    );
  }

  void _drawUJoint({
    required Canvas canvas,
    required double centerX,
    required double prongGap,
    required double prongWidth,
    required double leftProngLeft,
    required double rightProngLeft,
    required double prongBottom,
    required double jointBottom,
    required Color metalLight,
    required Color metalMid,
    required Color metalDark,
  }) {
    final leftInner = centerX - prongGap / 2;
    final rightInner = centerX + prongGap / 2;
    final leftOuter = leftProngLeft;
    final rightOuter = rightProngLeft + prongWidth;

    final path = Path()
      ..moveTo(leftOuter, prongBottom)
      ..lineTo(leftOuter, prongBottom + (jointBottom - prongBottom) * 0.35)
      ..quadraticBezierTo(
        leftOuter,
        jointBottom,
        leftInner,
        jointBottom,
      )
      ..lineTo(rightInner, jointBottom)
      ..quadraticBezierTo(
        rightOuter,
        jointBottom,
        rightOuter,
        prongBottom + (jointBottom - prongBottom) * 0.35,
      )
      ..lineTo(rightOuter, prongBottom)
      ..close();

    final bounds = path.getBounds();
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [metalLight, metalMid, metalDark],
      ).createShader(bounds);
    canvas.drawPath(path, paint);
  }

  void _drawStem({
    required Canvas canvas,
    required double left,
    required double top,
    required double width,
    required double height,
    required Color metalLight,
    required Color metalMid,
    required Color metalDark,
  }) {
    final rect = Rect.fromLTWH(left, top, width, height);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [metalLight, metalMid, metalDark],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.1 : 0.18)
      ..strokeWidth = width * 0.08;
    canvas.drawLine(
      Offset(left + width * 0.22, top),
      Offset(left + width * 0.22, top + height),
      highlight,
    );
  }

  void _drawBase({
    required Canvas canvas,
    required double centerX,
    required double top,
    required double bottom,
    required double maxWidth,
  }) {
    final height = bottom - top;
    final topWidth = maxWidth * 0.92;
    final neckWidth = maxWidth * 0.62;
    final bottomWidth = maxWidth;

    final path = Path()
      ..moveTo(centerX - topWidth / 2, top)
      ..lineTo(centerX + topWidth / 2, top)
      ..lineTo(centerX + neckWidth / 2, top + height * 0.38)
      ..lineTo(centerX + bottomWidth / 2, bottom)
      ..lineTo(centerX - bottomWidth / 2, bottom)
      ..lineTo(centerX - neckWidth / 2, top + height * 0.38)
      ..close();

    final bounds = path.getBounds();
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF3A3A3E), Color(0xFF121214), Color(0xFF2A2A2E)],
        stops: [0.0, 0.55, 1.0],
      ).createShader(bounds);
    canvas.drawPath(path, basePaint);

    final gloss = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.08 : 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = maxWidth * 0.04;
    canvas.drawLine(
      Offset(centerX - neckWidth * 0.2, top + height * 0.12),
      Offset(centerX - bottomWidth * 0.15, bottom - height * 0.08),
      gloss,
    );
  }

  @override
  bool shouldRepaint(covariant _TuningForkPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor ||
        oldDelegate.isDark != isDark;
  }
}
