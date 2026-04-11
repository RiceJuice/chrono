import 'package:chronoapp/features/login/presentation/pages/select_choir/provider/select_choir_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';



class LoginChoirCard extends ConsumerWidget {
  const LoginChoirCard({
    super.key,
    required this.label,
    required this.isActive,
  });

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wir beobachten den Zustand des Providers. 
    // Sobald sich 'state' im Provider ändert, baut Riverpod dieses Widget neu.
    final selectedChoir = ref.watch(selectedChoirProvider);
    
    // Wir prüfen, ob das Label dieser Karte dem aktuell ausgewählten Wert entspricht.
    final bool isSelected = (selectedChoir == label);

    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        // Wir rufen die Logik im Notifier auf (Toggle & Exklusivität).
        ref.read(selectedChoirProvider.notifier).selectChoir(label);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            // Die Dicke ändert sich flüssig durch den AnimatedContainer
            width: isSelected ? 4 : 1,
            // Hier nutzen wir beide Bedingungen für die Sichtbarkeit der Border
            color: (isActive || isSelected)
                ? Colors.white
                : Colors.white.withValues(alpha: 0.6),
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
      ),
    );
  }
}