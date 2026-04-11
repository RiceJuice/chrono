import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/login_routes.dart';
import '../../widgets/buttons.dart';
import '../../widgets/login_slide_scope.dart';
import '../../widgets/top_bar/login_top_bar.dart';

/// Einstieg: Marke, Kurztext und ein Schritt zur Zugangsdaten-Seite.
class StartScreenPage extends StatelessWidget {
  const StartScreenPage({super.key});

  static const _accent = Color(0xFFCBBBA0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LoginTopBar(),
              Expanded(
                child: LoginSlideLayer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      Text(
                        'Chrono',
                        style: GoogleFonts.libreBaskerville(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Chorplanung und Termine an einem Ort.',
                        style: GoogleFonts.libreBaskerville(
                          color: Colors.white70,
                          fontSize: 16,
                          height: 1.35,
                        ),
                      ),
                      const Spacer(),
                      Align(
                        child: LoginPrimaryButton(
                          label: 'Weiter',
                          color: _accent,
                          onPressed: () => context.go(LoginPaths.credentials),
                        ),
                      ),
                    ],
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
