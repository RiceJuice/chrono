import 'package:chronoapp/features/login/presentation/widgets/social_sign_in_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SocialSignInSection zeigt Google- und Apple-Buttons', (
    tester,
  ) async {
    if (!SocialSignInSection.isSupported) return;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SocialSignInSection(
            busyProvider: null,
            onGooglePressed: () {},
            onApplePressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Mit Google fortfahren'), findsOneWidget);
    expect(
      find.text('Mit Apple fortfahren'),
      SocialSignInSection.isAppleSignInSupported
          ? findsOneWidget
          : findsNothing,
    );
    expect(find.text('oder'), findsOneWidget);
  });
}
