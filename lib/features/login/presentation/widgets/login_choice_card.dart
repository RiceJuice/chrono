import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginChoiceCard extends StatelessWidget {
  const LoginChoiceCard({
    super.key,
    required this.title,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 92,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isSelected
              ? activeColor.withValues(alpha: 0.44)
              : Colors.white.withValues(alpha: 0.08),
          border: Border.all(
            color: isSelected
                ? activeColor.withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Text(
            title,
            style: GoogleFonts.libreBaskerville(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
