import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class LoginTopBar extends StatelessWidget {
  const LoginTopBar({super.key, this.onBack, this.middle});

  /// Wenn gesetzt, wird der Zurück-Button angezeigt und führt diesen Callback aus.
  final VoidCallback? onBack;
  final Widget? middle;

  @override
  Widget build(BuildContext context) {
    final Color fg = Theme.of(context).colorScheme.onSurface;
    final Widget? center = middle;

    if (center != null) {
      return Row(
        children: [
          SizedBox(
            width: 48,
            child: onBack != null
                ? IconButton(
                    onPressed: onBack,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: fg,
                    ),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  )
                : null,
          ),
          Expanded(child: Center(child: center)),
          SizedBox(
            width: 48,
            child: Align(
              alignment: Alignment.centerRight,
              child: SvgPicture.asset(
                "assets/domspatzen.svg",
                height: 20,
                width: 20,
              ),
            ),
          ),
        ],
      );
    }

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
        SvgPicture.asset("assets/domspatzen.svg", height: 20, width: 20),
      ],
    );
  }
}
