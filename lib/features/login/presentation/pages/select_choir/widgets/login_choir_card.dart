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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? Colors.white.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.12),
        ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6A7488), Color(0xFF181818)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
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
