import '../../domain/models/login_flow_step.dart';
import '../routes/login_paths.dart';

/// Route-Hilfen für den Login-Flow (Back-Pfad, Schrittnummer).
abstract final class LoginFlowRoute {
  static String? backPath(String location) {
    switch (location) {
      case LoginPaths.login:
        return null;
      case LoginPaths.credentials:
        return LoginPaths.login;
      case LoginPaths.emailConfirmation:
        return LoginPaths.credentials;
      case LoginPaths.role:
        return LoginPaths.credentials;
      case LoginPaths.personalData:
        return LoginPaths.role;
      case LoginPaths.choir:
        return LoginPaths.personalData;
      case LoginPaths.success:
        return null;
      default:
        return null;
    }
  }

  static int? stepNumber(String location) {
    switch (location) {
      case LoginPaths.login:
        return null;
      case LoginPaths.credentials:
      case LoginPaths.emailConfirmation:
        return LoginFlowStep.credentials.stepNumber;
      case LoginPaths.role:
        return LoginFlowStep.role.stepNumber;
      case LoginPaths.personalData:
        return LoginFlowStep.personalData.stepNumber;
      case LoginPaths.choir:
        return LoginFlowStep.choir.stepNumber;
      case LoginPaths.success:
        return null;
      default:
        return null;
    }
  }
}
