import '../../domain/models/login_flow_role_ids.dart';

class LoginFlowDraft {
  LoginFlowDraft._();

  static final LoginFlowDraft instance = LoginFlowDraft._();

  String email = '';
  String password = '';
  String passwordConfirm = '';
  String role = LoginFlowRoleIds.guardian;
  String firstName = '';
  String lastName = '';
  String? schoolClass;
  String? schoolTrack;
  int choirPage = 1;
  String voice = '';

  void reset() {
    email = '';
    password = '';
    passwordConfirm = '';
    role = LoginFlowRoleIds.guardian;
    firstName = '';
    lastName = '';
    schoolClass = null;
    schoolTrack = null;
    choirPage = 1;
    voice = '';
  }
}
