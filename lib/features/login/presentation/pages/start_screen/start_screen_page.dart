import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/login_scroll_surface.dart';
import '../../widgets/login_start_auth_panel.dart';

/// Einstieg: Marke, Kurztext und Auth-Optionen in Squircle-Box.
///
/// Wird innerhalb von [LoginOnboardingShell] gerendert; Top-Bar liegt im Shell.
class StartScreenPage extends StatelessWidget {
  const StartScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
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
                            color: scheme.onSurface,
                            fontSize: 44,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Chorplanung und Termine an einem Ort.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.78),
                                fontSize: 16,
                                height: 1.35,
                              ) ??
                              TextStyle(
                                color: scheme.onSurface.withValues(alpha: 0.78),
                                fontSize: 16,
                                height: 1.35,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const LoginStartAuthPanel(),
              ],
            ),
          ),
        );
      },
    );
  }
}
