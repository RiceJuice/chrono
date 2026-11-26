class LoginFlowDraft {
  LoginFlowDraft._();

  static final LoginFlowDraft instance = LoginFlowDraft._();

  String email = '';
  String password = '';
  String passwordConfirm = '';
  String role = '';
  String firstName = '';
  String lastName = '';
  String? schoolClass;
  String? schoolTrack;
  String? diet;
  String? artsSubject;
  String? languageSubject;
  int choirPage = 1;
  String voice = '';

  void reset() {
    email = '';
    password = '';
    passwordConfirm = '';
    role = '';
    firstName = '';
    lastName = '';
    schoolClass = null;
    schoolTrack = null;
    diet = null;
    artsSubject = null;
    languageSubject = null;
    choirPage = 1;
    voice = '';
  }
}
