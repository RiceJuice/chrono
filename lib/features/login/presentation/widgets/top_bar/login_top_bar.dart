import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class LoginTopBar extends StatelessWidget {
  const LoginTopBar({super.key, this.onBack});

  /// Wenn gesetzt, wird der Zurück-Button angezeigt und führt diesen Callback aus.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final Color fg = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        if (onBack != null)
          IconButton(
            onPressed: onBack,
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: fg,
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
        const Spacer(),
        SvgPicture.asset("assets/domspatzen.svg", height: 20, width: 20,),
      ],
    );
  }
}
