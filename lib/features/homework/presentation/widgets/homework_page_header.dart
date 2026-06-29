import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeworkPageHeader extends StatelessWidget {
  const HomeworkPageHeader({super.key, this.onAddPressed});

  static const _addButtonSize = 56.0;
  static const _addIconSize = 30.0;

  final VoidCallback? onAddPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.s, AppSpacing.s, AppSpacing.s),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Aufgaben',
              style: GoogleFonts.libreBaskerville(
                textStyle: Theme.of(context).textTheme.headlineLarge,
                fontSize: 26,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: scheme.onSurface,
              ),
            ),
          ),
          if (onAddPressed != null)
            SizedBox(
              width: _addButtonSize,
              height: _addButtonSize,
              child: IconButton(
                onPressed: onAddPressed,
                tooltip: 'Neue Aufgabe',
                iconSize: _addIconSize,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: scheme.onSurface,
                ),
                icon: const Icon(Icons.add),
              ),
            ),
        ],
      ),
    );
  }
}
