class LoginFlowDraft {
  LoginFlowDraft._();

  static final LoginFlowDraft instance = LoginFlowDraft._();

  String email = '';
  String password = '';
  String passwordConfirm = '';
  String role = 'Elternteil';
  String firstName = '';
  String lastName = '';
  String? schoolClass;
  int choirPage = 1;
  String voice = '';

  void reset() {
    email = '';
    password = '';
    passwordConfirm = '';
    role = 'Elternteil';
    firstName = '';
    lastName = '';
    schoolClass = null;
    choirPage = 1;
    voice = '';
  }
}
