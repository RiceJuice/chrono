import '../../domain/models/profile_gate_data.dart';
import 'login_paths.dart';

/// Eine einzelne Station im Onboarding-Flow nach erfolgreichem Credentials-Step.
/// Die Reihenfolge in [loginFlowSpecs] steuert Resolver und Slide-Richtung.
class LoginFlowStepSpec {
  const LoginFlowStepSpec({
    required this.path,
    required this.isSatisfiedBy,
  });

  final String path;
  final bool Function(ProfileGateData data) isSatisfiedBy;
}

bool _isNonEmpty(String? value) => value != null && value.trim().isNotEmpty;

/// Geordnete Liste aller Onboarding-Schritte. Neue Schritte einfach hier
/// einhängen – Resolver, Router-Guard und Slide-Reihenfolge ziehen automatisch
/// nach.
final List<LoginFlowStepSpec> loginFlowSpecs = <LoginFlowStepSpec>[
  LoginFlowStepSpec(
    path: LoginPaths.emailConfirmation,
    isSatisfiedBy: (data) => data.emailConfirmed,
  ),
  LoginFlowStepSpec(
    path: LoginPaths.role,
    isSatisfiedBy: (data) => _isNonEmpty(data.role),
  ),
  LoginFlowStepSpec(
    path: LoginPaths.personalData,
    isSatisfiedBy: (data) =>
        _isNonEmpty(data.firstName) &&
        _isNonEmpty(data.lastName) &&
        _isNonEmpty(data.className),
  ),
  LoginFlowStepSpec(
    path: LoginPaths.choir,
    isSatisfiedBy: (data) =>
        _isNonEmpty(data.voice) && _isNonEmpty(data.choir),
  ),
];

/// Position eines Login-Pfads im Flow (Start/Credentials zuerst, dann die
/// registrierten Specs in Reihenfolge). Wird von der Slide-Animation genutzt,
/// um Richtung Vor/Zurück zu bestimmen. Liefert `-1` für unbekannte Pfade.
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
  return -1;
}

/// Erste offene Onboarding-Route für einen eingeloggten Nutzer, oder `null`
/// wenn das Profil vollständig ist. Für Sessions-lose Zustände ebenfalls `null`.
String? resolveRequiredOnboardingPath(ProfileGateData data) {
  if (!data.hasSession) return null;
  for (final spec in loginFlowSpecs) {
    if (!spec.isSatisfiedBy(data)) return spec.path;
  }
  return null;
}

/// Gesamtmenge aller Login-Unterpfade, die der Router akzeptiert – inklusive
/// Start- und Credentials-Seite.
Set<String> get onboardingLoginPaths => <String>{
      LoginPaths.login,
      LoginPaths.credentials,
      for (final spec in loginFlowSpecs) spec.path,
    };
