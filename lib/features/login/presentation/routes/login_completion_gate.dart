import 'login_paths.dart';

/// Keeps the optional final steps pending while auth/profile refreshes move
/// the router through /loading or dispose the form that initiated sign-in.
class LoginCompletionGate {
  bool _pending = false;

  void begin() => _pending = true;

  /// Call only after every required profile step has been satisfied.
  String? redirectCompletedProfile(String location) {
    if (location == LoginPaths.success) {
      _pending = false;
      return null;
    }
    if (location == LoginPaths.notificationsIntro ||
        location == LoginPaths.notificationsPermission) {
      return null;
    }
    if (_pending) return LoginPaths.notificationsIntro;
    return null;
  }
}
