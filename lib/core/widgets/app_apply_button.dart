import 'package:chronoapp/core/widgets/app_glass_icon_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppApplyButton extends StatelessWidget {
  const AppApplyButton({
    super.key,
    required this.onPressed,
    this.label = 'Übernehmen',
    this.filled = true,
  }) : _cancel = false;

  const AppApplyButton.cancel({super.key, required this.onPressed})
    : label = 'Abbrechen',
      filled = false,
      _cancel = true;

  final VoidCallback? onPressed;
  final String label;
  final bool filled;
  final bool _cancel;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      return AppGlassIconButton(
        icon: _cancel ? Icons.close : Icons.check,
        tooltip: label,
        onPressed: onPressed,
      );
    }

    final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final theme = Theme.of(context);
    final style = android
        ? TextButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: theme.brightness == Brightness.dark
                ? theme.colorScheme.inverseSurface
                : null,
            textStyle: GoogleFonts.libreBaskerville(
              textStyle: theme.textTheme.labelLarge,
              fontWeight: FontWeight.w700,
            ),
          )
        : null;
    final child = Text(label);

    return filled
        ? FilledButton(onPressed: onPressed, style: style, child: child)
        : TextButton(onPressed: onPressed, style: style, child: child);
  }
}
