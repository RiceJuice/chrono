import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/login_routes.dart';
import '../../widgets/buttons.dart';
import '../../widgets/login_scroll_surface.dart';

/// Einstieg: Marke, Kurztext und ein Schritt zur Zugangsdaten-Seite.
///
/// Wird innerhalb von [LoginOnboardingShell] gerendert; Top-Bar liegt im Shell.
class StartScreenPage extends StatelessWidget {
  const StartScreenPage({super.key});

  static const _accent = Color(0xFFCBBBA0);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return LoginScrollSurface(
          child: SizedBox(
            height: constraints.maxHeight,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
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
                          textAlign: TextAlign.center,
                          style: GoogleFonts.libreBaskerville(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: LoginPrimaryButton(
                      label: 'Weiter',
                      color: _accent,
                      onPressed: () => context.go(LoginPaths.credentials),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
