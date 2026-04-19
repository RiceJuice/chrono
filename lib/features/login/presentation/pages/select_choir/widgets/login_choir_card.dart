import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginChoirCard extends StatelessWidget {
  const LoginChoirCard({
    super.key,
    required this.label,
    required this.isActive,
  });

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool light = Theme.of(context).brightness == Brightness.light;
    final Color borderColor = light
        ? scheme.surfaceContainerHighest
        : (isActive
            ? Colors.white
            : Colors.white.withValues(alpha: 0.6));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          width: isActive ? 4 : 1,
          color: borderColor,
        ),
        color: const Color(0xFFCBBBA0),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 14,
            bottom: 12,
            child: Text(
              label,
              style: GoogleFonts.libreBaskerville(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}