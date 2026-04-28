import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginChoirCard extends StatelessWidget {
  const LoginChoirCard({
    super.key,
    required this.label,
    required this.isActive,
    this.imageAsset,
  });

  final String label;
  final bool isActive;
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = scheme.brightness == Brightness.dark;
    const double radius = AppRadius.xl;
    final double ringWidth = isActive ? 3.2 : 1.2;
    const Color accent = Color(0xFFCBBBA0);
    final Color borderColor = isActive
        ? (isDark
              ? scheme.onSurface
              : scheme.onSurface.withValues(alpha: 0.34))
        : (isDark
              ? scheme.onSurface.withValues(alpha: 0.42)
              : scheme.onSurface.withValues(alpha: 0.22));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: borderColor,
      ),
      child: Padding(
        padding: EdgeInsets.all(ringWidth),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - ringWidth),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageAsset case final asset?)
                Positioned.fill(child: Image.asset(asset, fit: BoxFit.cover))
              else
                const Positioned.fill(child: ColoredBox(color: accent)),
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
        ),
      ),
    );
  }
}
