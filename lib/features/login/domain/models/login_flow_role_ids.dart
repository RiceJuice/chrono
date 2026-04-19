/// Im Profil / Login-Entwurf verwendete Rollen-Bezeichner (Sprache der API).
///
/// UI-Logik soll diese Konstanten nutzen, damit später weitere Rollen
/// ergänzt werden können, ohne Magic Strings zu verstreuen.
class LoginFlowRoleIds {
  LoginFlowRoleIds._();

  static const String student = 'Schüler';
  static const String guardian = 'Elternteil';
}
