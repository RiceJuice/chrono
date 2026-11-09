import 'package:chronoapp/features/login/presentation/routes/login_completion_gate.dart';
import 'package:chronoapp/features/login/presentation/routes/login_paths.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'auth refresh cannot skip push onboarding through loading or calendar',
    () {
      for (final location in [
        '/loading',
        '/calendar',
        LoginPaths.credentials,
        LoginPaths.choir,
      ]) {
        final gate = LoginCompletionGate()..begin();
        expect(
          gate.redirectCompletedProfile(location),
          LoginPaths.notificationsIntro,
        );
        expect(
          gate.redirectCompletedProfile(LoginPaths.notificationsIntro),
          isNull,
        );
        expect(
          gate.redirectCompletedProfile(LoginPaths.notificationsPermission),
          isNull,
        );
        // Another profile refresh during these screens must keep them visible.
        expect(
          gate.redirectCompletedProfile(LoginPaths.notificationsPermission),
          isNull,
        );
        expect(gate.redirectCompletedProfile(LoginPaths.success), isNull);
        expect(gate.redirectCompletedProfile('/calendar'), isNull);
      }
    },
  );

  test('restoring a complete session does not repeat onboarding', () {
    final gate = LoginCompletionGate();
    expect(gate.redirectCompletedProfile('/loading'), isNull);
    expect(gate.redirectCompletedProfile('/calendar'), isNull);
  });

  test('another sign-in starts a fresh completion flow', () {
    final gate = LoginCompletionGate()..begin();
    gate.redirectCompletedProfile(LoginPaths.success);
    gate.begin();
    expect(
      gate.redirectCompletedProfile('/loading'),
      LoginPaths.notificationsIntro,
    );
  });
}
