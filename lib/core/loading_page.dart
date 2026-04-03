import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.secondary,
      child: Center(
        child: SvgPicture.asset(
          'assets/domspatzen.svg',
          colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.tertiary, BlendMode.srcIn),
        ),
      ),
    );
  }
}
