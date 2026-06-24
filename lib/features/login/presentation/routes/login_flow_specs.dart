import '../../../../core/auth/profile_role_ids.dart';
import '../../domain/models/login_flow_role_ids.dart';
import '../../domain/models/profile_gate_data.dart';
import 'login_paths.dart';

/// Eine einzelne Station im Onboarding-Flow nach erfolgreichem Credentials-Step.
class LoginFlowStepSpec {
  const LoginFlowStepSpec({
    required this.path,
    required this.isSatisfiedBy,
    this.appliesTo,
  });

  final String path;
  final bool Function(ProfileGateData data) isSatisfiedBy;

  /// `null` = für alle Rollen; sonst nur wenn Prädikat true ist.
  final bool Function(ProfileGateData data)? appliesTo;
}

bool _isNonEmpty(String? value) => value != null && value.trim().isNotEmpty;

bool _isAdminProfile(ProfileGateData data) =>
    data.role?.trim() == ProfileRoleIds.admin;

bool _isGuardianProfile(ProfileGateData data) =>
    data.role?.trim() == LoginFlowRoleIds.guardian;

bool _isStudentProfile(ProfileGateData data) =>
    !_isAdminProfile(data) && !_isGuardianProfile(data);

/// Geordnete Liste aller Onboarding-Schritte.
final List<LoginFlowStepSpec> loginFlowSpecs = <LoginFlowStepSpec>[
  LoginFlowStepSpec(
    path: LoginPaths.emailConfirmation,
    isSatisfiedBy: (data) => data.emailConfirmed,
  ),
  LoginFlowStepSpec(
    path: LoginPaths.role,
    isSatisfiedBy: (data) => _isNonEmpty(data.role),
  ),
  // Schüler: vollständige persönliche Daten
  LoginFlowStepSpec(
    path: LoginPaths.personalData,
    appliesTo: _isStudentProfile,
    isSatisfiedBy: (data) =>
        _isAdminProfile(data) ||
        (_isNonEmpty(data.firstName) &&
            _isNonEmpty(data.lastName) &&
            _isNonEmpty(data.className) &&
            _isNonEmpty(data.schoolTrack)),
  ),
  LoginFlowStepSpec(
    path: LoginPaths.choir,
    appliesTo: _isStudentProfile,
    isSatisfiedBy: (data) =>
        _isAdminProfile(data) ||
        (_isNonEmpty(data.voice) && _isNonEmpty(data.choir)),
  ),
  // Elternteil: eigener Name
  LoginFlowStepSpec(
    path: LoginPaths.personalData,
    appliesTo: _isGuardianProfile,
    isSatisfiedBy: (data) =>
        _isNonEmpty(data.firstName) && _isNonEmpty(data.lastName),
  ),
  // Elternteil: Kind auswählen und auf Bestätigung warten
  LoginFlowStepSpec(
    path: LoginPaths.selectChild,
    appliesTo: _isGuardianProfile,
    isSatisfiedBy: (data) => data.hasConfirmedGuardianLink,
  ),
];

List<LoginFlowStepSpec> _specsFor(ProfileGateData data) {
  return loginFlowSpecs.where((spec) {
    final applies = spec.appliesTo;
    return applies == null || applies(data);
  }).toList(growable: false);
}

int loginFlowOrderIndex(String path) {
  switch (path) {
    case LoginPaths.login:
      return 0;
    case LoginPaths.credentials:
      return 1;
  }
  for (var i = 0; i < loginFlowSpecs.length; i++) {
    if (loginFlowSpecs[i].path == path) return i + 2;
  }
  if (path == LoginPaths.success) {
    return loginFlowSpecs.length + 2;
  }
  return -1;
}

String? resolveRequiredOnboardingPath(ProfileGateData data) {
  if (!data.hasSession) return null;
  for (final spec in _specsFor(data)) {
    if (!spec.isSatisfiedBy(data)) return spec.path;
  }
  return null;
}

Set<String> get onboardingLoginPaths => <String>{
      LoginPaths.login,
      LoginPaths.credentials,
      for (final spec in loginFlowSpecs) spec.path,
      LoginPaths.success,
    };
