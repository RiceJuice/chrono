import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../routes/login_paths.dart';

/// Physical size keeps tablet detection stable in iPad split views.
abstract final class LoginTabletLayout {
  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide >= 600 ||
      View.of(context).physicalSize.shortestSide /
              View.of(context).devicePixelRatio >=
          600;

  static bool isAppleTablet(BuildContext context) =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.iOS &&
      isTablet(context);
}

/// The same pages and styling as iPhone, with comfortable iPad content bounds.
class LoginTabletFrame extends StatelessWidget {
  const LoginTabletFrame({
    super.key,
    required this.location,
    required this.child,
  });

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: location == LoginPaths.choir ? 620 : 560,
              maxHeight: location == LoginPaths.login ? 740 : 960,
            ),
            child: FocusTraversalGroup(child: AutofillGroup(child: child)),
          ),
        ),
      ),
    );
  }
}
