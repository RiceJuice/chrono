import '../../domain/models/login_flow_role_ids.dart';
import '../../domain/models/login_flow_step.dart';

enum _LoginFlowRoleKind {
  student,
  guardian,
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

final class LoginFlowRoleUi {
  const LoginFlowRoleUi._(this._kind);

  final _LoginFlowRoleKind _kind;

  factory LoginFlowRoleUi.fromStoredRoleLabel(String storedRoleLabel) {
    return LoginFlowRoleUi._(
      _LoginFlowRoleKind.fromStoredLabel(storedRoleLabel),
    );
  }

  bool get isGuardian => _kind == _LoginFlowRoleKind.guardian;

  String scaffoldTitle(LoginFlowStep step) {
    switch (_kind) {
      case _LoginFlowRoleKind.guardian:
        return switch (step) {
          LoginFlowStep.personalData => 'Deine Daten',
          LoginFlowStep.selectChild => 'Kind auswählen',
          LoginFlowStep.guardianPending => 'Bestätigung ausstehend',
          LoginFlowStep.credentials ||
          LoginFlowStep.role ||
          LoginFlowStep.choir =>
            step.title,
        };
      case _LoginFlowRoleKind.student:
      case _LoginFlowRoleKind.other:
        return switch (step) {
          LoginFlowStep.personalData => 'Deine Daten',
          LoginFlowStep.choir => 'Dein Chor',
          _ => step.title,
        };
    }
  }
}
