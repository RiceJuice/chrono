import 'package:chronoapp/features/settings/presentation/helpers/settings_profile_display.dart';
import 'package:chronoapp/features/settings/presentation/widgets/profile_page_layout.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('empty profile uses the requested action label', () {
    expect(settingsProfileName(null), 'Profil anpassen');
  });

  for (final size in [
    const Size(390, 844),
    const Size(834, 1194),
    const Size(1194, 834),
    const Size(507, 834),
  ]) {
    testWidgets('profile adapts to $size', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfilePageLayout(
              header: SizedBox(key: Key('header'), height: 280),
              account: SizedBox(key: Key('account'), height: 240),
            ),
          ),
        ),
      );
      final header = tester.getRect(find.byKey(const Key('header')));
      final account = tester.getRect(find.byKey(const Key('account')));
      expect(account.top, greaterThan(header.bottom));
      expect(account.left, header.left);
      expect(account.width, header.width);
      expect(header.width, lessThanOrEqualTo(540));
      expect(header.center.dx, closeTo(size.width / 2, 0.1));
      expect(account.right, lessThanOrEqualTo(size.width - 20));
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
