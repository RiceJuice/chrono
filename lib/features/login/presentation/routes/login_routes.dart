import 'package:go_router/go_router.dart';

import '../pages/credentials/credentials_page.dart';
import '../pages/credentials/widgets/account_auth_mode.dart';
import '../pages/email_confirmation/email_confirmation_page.dart';
import '../pages/select_choir/select_choir.dart';
import '../pages/select_personal_data/personalData.dart';
import '../pages/start_screen/start_screen_page.dart';
import '../pages/select_role/select_role.dart';

abstract final class LoginPaths {
  static const login = '/login';
  static const credentials = '/login/credentials';
  static const role = '/login/role';
  static const personalData = '/login/personal-data';
  static const choir = '/login/choir';
  static const emailConfirmation = '/login/email-confirmation';
}

AccountAuthMode _authModeFromQuery(GoRouterState state) {
  final raw = state.uri.queryParameters['mode'];
  if (raw == 'signUp') return AccountAuthMode.signUp;
  return AccountAuthMode.signIn;
}

final List<RouteBase> loginRoutes = [
  GoRoute(
    path: LoginPaths.login,
    builder: (context, state) => const StartScreenPage(),
    routes: [
      GoRoute(
        path: 'credentials',
        builder: (context, state) => CredentialsPage(
          initialMode: _authModeFromQuery(state),
        ),
      ),
      GoRoute(
        path: 'role',
        builder: (context, state) => const SelectRolePage(),
      ),
      GoRoute(
        path: 'personal-data',
        builder: (context, state) => const PersonalDataPage(),
      ),
      GoRoute(
        path: 'choir',
        builder: (context, state) => const ChoirPage(),
      ),
      GoRoute(
        path: 'email-confirmation',
        builder: (context, state) => const EmailConfirmationPage(),
      ),
    ],
  ),
];
