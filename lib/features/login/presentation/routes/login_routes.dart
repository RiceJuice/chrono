import 'package:go_router/go_router.dart';

import '../pages/select_choir/select_choir.dart';
import '../pages/select_personal_data/personalData.dart';
import '../pages/register/register.dart';
import '../pages/select_role/select_role.dart';

abstract final class LoginPaths {
  static const login = '/login';
  static const register = '/login/register';
  static const role = '/login/role';
  static const personalData = '/login/personal-data';
  static const choir = '/login/choir';
}

final List<RouteBase> loginRoutes = [
  GoRoute(
    path: LoginPaths.login,
    redirect: (context, state) {
      if (state.uri.path == LoginPaths.login) {
        return LoginPaths.register;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: 'register',
        builder: (context, state) => const RegisterPage(),
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
    ],
  ),
];
