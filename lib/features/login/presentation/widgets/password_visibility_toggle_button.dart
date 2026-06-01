import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Passwort-Sichtbarkeit ohne Material-Splash; der Durchstreich-Strich wird animiert.
class PasswordVisibilityToggleButton extends StatefulWidget {
  const PasswordVisibilityToggleButton({
    super.key,
    required this.obscured,
    required this.onPressed,
    required this.iconColor,
    this.tooltipObscured = 'Passwort anzeigen',
    this.tooltipVisible = 'Passwort verbergen',
  });

  final bool obscured;
  final VoidCallback onPressed;
  final Color iconColor;
  final String tooltipObscured;
  final String tooltipVisible;

  @override
  State<PasswordVisibilityToggleButton> createState() =>
      _PasswordVisibilityToggleButtonState();
}

class _PasswordVisibilityToggleButtonState
    extends State<PasswordVisibilityToggleButton>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 220);

  late final AnimationController _strikeController;
  late final Animation<double> _strikeProgress;

  @override
  void initState() {
    super.initState();
    _strikeController = AnimationController(
      vsync: this,
      duration: _duration,
      value: widget.obscured ? 1 : 0,
    );
    _strikeProgress = CurvedAnimation(
      parent: _strikeController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(PasswordVisibilityToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscured == widget.obscured) return;
    if (widget.obscured) {
      _strikeController.forward();
    } else {
      _strikeController.reverse();
    }
  }

  @override
  void dispose() {
    _strikeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        HapticFeedback.selectionClick();
        widget.onPressed();
      },
      tooltip: widget.obscured ? widget.tooltipObscured : widget.tooltipVisible,
      style: IconButton.styleFrom(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      icon: AnimatedBuilder(
        animation: _strikeProgress,
        builder: (context, _) {
          return _AnimatedVisibilityEye(
            strikeProgress: _strikeProgress.value,
            color: widget.iconColor,
          );
        },
      ),
    );
  }
}

class _AnimatedVisibilityEye extends StatelessWidget {
  const _AnimatedVisibilityEye({
    required this.strikeProgress,
    required this.color,
  });

  final double strikeProgress;
  final Color color;

  static const double _iconSize = 24;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _iconSize,
      height: _iconSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.visibility_outlined,
            size: _iconSize,
            color: color,
          ),
          CustomPaint(
            size: const Size(_iconSize, _iconSize),
            painter: _EyeStrikePainter(
              progress: strikeProgress,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Diagonale Linie wie bei [Icons.visibility_off_outlined], von oben-links nach unten-rechts.
class _EyeStrikePainter extends CustomPainter {
  _EyeStrikePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final start = Offset(size.width * 0.16, size.height * 0.26);
    final end = Offset(size.width * 0.84, size.height * 0.74);
    final tip = Offset.lerp(start, end, progress.clamp(0.0, 1.0))!;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(start, tip, paint);
  }

  @override
  bool shouldRepaint(_EyeStrikePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
