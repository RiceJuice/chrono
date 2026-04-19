import '../../domain/models/login_flow_role_ids.dart';
import '../../domain/models/login_flow_step.dart';

enum _LoginFlowRoleKind {
  student,
  guardian,
  /// Unbekannte oder künftige API-Strings: konservativ wie [student] behandeln.
  other,
  ;

  static _LoginFlowRoleKind fromStoredLabel(String label) {
    switch (label.trim()) {
      case LoginFlowRoleIds.guardian:
        return _LoginFlowRoleKind.guardian;
      case LoginFlowRoleIds.student:
        return _LoginFlowRoleKind.student;
      default:
        return _LoginFlowRoleKind.other;
    }
  }
}

/// Rollenabhängige Texte und später weitere Anpassungen im Login-Onboarding.
///
/// Neue Rolle: Konstante in [LoginFlowRoleIds], Zuordnung in [_LoginFlowRoleKind.fromStoredLabel],
/// dann hier `switch (_kind)` / weitere Getter (Feldbeschriftungen, Toasts, …) ergänzen.
final class LoginFlowRoleUi {
  const LoginFlowRoleUi._(this._kind);

  final _LoginFlowRoleKind _kind;

  factory LoginFlowRoleUi.fromStoredRoleLabel(String storedRoleLabel) {
    return LoginFlowRoleUi._(
      _LoginFlowRoleKind.fromStoredLabel(storedRoleLabel),
    );
  }

  bool get isGuardian => _kind == _LoginFlowRoleKind.guardian;

  /// Titel im [LoginStepScaffold]; fällt sonst auf den Standard aus [LoginFlowStep.title] zurück.
  String scaffoldTitle(LoginFlowStep step) {
    switch (_kind) {
      case _LoginFlowRoleKind.guardian:
        switch (step) {
          case LoginFlowStep.personalData:
            return 'Mein Kind';
          case LoginFlowStep.choir:
            return 'Der Chor';
          case LoginFlowStep.credentials:
          case LoginFlowStep.role:
            return step.title;
        }
      case _LoginFlowRoleKind.student:
      case _LoginFlowRoleKind.other:
        return step.title;
    }
  }
}
