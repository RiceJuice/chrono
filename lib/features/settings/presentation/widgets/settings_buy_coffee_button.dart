import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:flutter/material.dart';

/// Dekorativer „Buy us a coffee“-Button — noch ohne Aktion/Link.
class SettingsBuyCoffeeButton extends StatelessWidget {
  const SettingsBuyCoffeeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? const [Color(0xFF3A2414), Color(0xFF5A3824)]
          : const [Color(0xFFFFF6EA), Color(0xFFF0DCC4)],
    );

    final titleColor = isDark ? const Color(0xFFFFE8CC) : const Color(0xFF4A2C18);
    final subtitleColor = titleColor.withValues(alpha: 0.72);

    return DecoratedBox(
      decoration: ShapeDecoration(
        gradient: gradient,
        shape: AppSquircle.shape(
          AppRadius.l,
          side: BorderSide(
            color: isDark
                ? const Color(0xFFFFB86B).withValues(alpha: 0.22)
                : const Color(0xFFC58B4E).withValues(alpha: 0.28),
          ),
        ),
        shadows: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF8B5A2B))
                .withValues(alpha: isDark ? 0.35 : 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 18, 14),
        child: Row(
          children: [
            _CoffeeCupIllustration(
              size: 52,
              isDark: isDark,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spendier uns einen Kaffee',
                    style: textTheme.titleSmall?.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Vielen Dank für eure Unterstützung',
                    style: textTheme.bodySmall?.copyWith(
                      color: subtitleColor,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoffeeCupIllustration extends StatelessWidget {
  const _CoffeeCupIllustration({
    required this.size,
    required this.isDark,
  });

  final double size;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CoffeeCupPainter(isDark: isDark),
      ),
    );
  }
}

class _CoffeeCupPainter extends CustomPainter {
  const _CoffeeCupPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final steamPaint = Paint()
      ..color = (isDark ? const Color(0xFFFFD9A8) : const Color(0xFFB8844E))
          .withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round;

    _drawSteam(canvas, steamPaint, Offset(w * 0.34, h * 0.06), w * 0.12);
    _drawSteam(canvas, steamPaint, Offset(w * 0.5, h * 0.02), w * 0.14);
    _drawSteam(canvas, steamPaint, Offset(w * 0.66, h * 0.07), w * 0.11);

    final cupBody = Path()
      ..moveTo(w * 0.18, h * 0.36)
      ..quadraticBezierTo(w * 0.16, h * 0.52, w * 0.22, h * 0.82)
      ..quadraticBezierTo(w * 0.34, h * 0.92, w * 0.5, h * 0.92)
      ..quadraticBezierTo(w * 0.66, h * 0.92, w * 0.78, h * 0.82)
      ..quadraticBezierTo(w * 0.84, h * 0.52, w * 0.82, h * 0.36)
      ..close();

    final cupFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? const [Color(0xFFF8F0E6), Color(0xFFD9C9B8)]
            : const [Color(0xFFFFFFFF), Color(0xFFE9DFD2)],
      ).createShader(Rect.fromLTWH(0, h * 0.36, w, h * 0.56));

    canvas.drawPath(cupBody, cupFill);

    final cupStroke = Paint()
      ..color = isDark ? const Color(0xFF8A6A52) : const Color(0xFFC4A484)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035;
    canvas.drawPath(cupBody, cupStroke);

    final coffeeRect = Rect.fromLTWH(w * 0.2, h * 0.34, w * 0.6, h * 0.14);
    final coffeePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.4),
        radius: 1.1,
        colors: isDark
            ? const [Color(0xFF8B4E1E), Color(0xFF5C2F12)]
            : const [Color(0xFF9A5A28), Color(0xFF6B3A18)],
      ).createShader(coffeeRect);
    canvas.drawOval(coffeeRect, coffeePaint);

    final foamPaint = Paint()
      ..color = (isDark ? const Color(0xFFFFEED8) : const Color(0xFFFFF8F0))
          .withValues(alpha: 0.9);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.42, h * 0.37),
        width: w * 0.16,
        height: h * 0.05,
      ),
      foamPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.58, h * 0.39),
        width: w * 0.12,
        height: h * 0.04,
      ),
      foamPaint,
    );

    final handlePath = Path()
      ..moveTo(w * 0.8, h * 0.44)
      ..cubicTo(
        w * 0.98,
        h * 0.42,
        w * 0.98,
        h * 0.72,
        w * 0.8,
        h * 0.7,
      );
    final handlePaint = Paint()
      ..color = isDark ? const Color(0xFF8A6A52) : const Color(0xFFC4A484)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.055
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(handlePath, handlePaint);

    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.18 : 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.28, h * 0.5),
      Offset(w * 0.3, h * 0.72),
      shinePaint,
    );
  }

  void _drawSteam(
    Canvas canvas,
    Paint paint,
    Offset start,
    double height,
  ) {
    final path = Path()
      ..moveTo(start.dx, start.dy + height)
      ..cubicTo(
        start.dx - height * 0.35,
        start.dy + height * 0.55,
        start.dx + height * 0.35,
        start.dy + height * 0.2,
        start.dx,
        start.dy,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CoffeeCupPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
