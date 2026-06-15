import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routes/login_routes.dart';
import 'login_social_sign_in_block.dart';
import 'social_sign_in_section.dart';

/// Startscreen: Squircle-Box mit Apple, Google und E-Mail unten.
class LoginStartAuthPanel extends StatelessWidget {
  const LoginStartAuthPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return LoginSocialSignInBlock(
      showDivider: false,
      presentation: SocialSignInPresentation.startSheet,
      trailing: [
        LoginAuthOptionButton(
          label: 'Mit E-Mail fortfahren',
          variant: LoginAuthOptionButtonVariant.primary,
          isLoading: false,
          onPressed: () => context.go(LoginPaths.credentials),
        ),
      ],
    );
  }
}
