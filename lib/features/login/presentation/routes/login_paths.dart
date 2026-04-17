/// Statische Login-Pfade — als reine String-Konstanten, damit sie auch aus
/// Resolver-Code ohne Flutter-/go_router-Abhängigkeit referenziert werden
/// können.
abstract final class LoginPaths {
  static const login = '/login';
  static const credentials = '/login/credentials';
  static const role = '/login/role';
  static const personalData = '/login/personal-data';
  static const choir = '/login/choir';
  static const emailConfirmation = '/login/email-confirmation';
}
