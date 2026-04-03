import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class LoginTopBar extends StatelessWidget {
  const LoginTopBar({super.key, required this.canGoBack, required this.onBack});

  final bool canGoBack;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: canGoBack ? onBack : null,
          style: IconButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white.withValues(alpha: 0.3),
          ),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        const Spacer(),
        SvgPicture.asset("assets/domspatzen.svg", height: 20, width: 20,),
      ],
    );
  }
}
