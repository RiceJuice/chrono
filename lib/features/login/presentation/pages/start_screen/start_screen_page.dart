import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/login_paths.dart';
import '../../widgets/login_flow_body.dart';
import '../../widgets/login_flow_spacing.dart';
import '../../widgets/login_start_auth_panel.dart';

/// Einstieg: Marke, Kurztext und Auth-Optionen in Squircle-Box.
class StartScreenPage extends StatelessWidget {
  const StartScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool compact = LoginFlowSpacing.isCompact(context);
    final double titleSize = compact ? 36 : 44;

    return LoginFlowBody(
      location: LoginPaths.login,
      fillViewport: true,
      pinBottomBarToEdge: true,
      bottomBar: const LoginStartAuthPanel(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Chrono',
            style: GoogleFonts.libreBaskerville(
              color: scheme.onSurface,
              fontSize: titleSize,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Chorplanung und Termine an einem Ort.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.78),
                    fontSize: compact ? 14 : 16,
                    height: 1.35,
                  ) ??
                  TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.78),
                    fontSize: compact ? 14 : 16,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
