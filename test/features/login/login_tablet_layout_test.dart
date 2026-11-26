import 'package:flutter/foundation.dart';
import 'package:chronoapp/features/login/presentation/widgets/login_split_screen.dart';
import 'package:chronoapp/features/login/presentation/widgets/login_photo_carousel.dart';
import 'package:chronoapp/features/login/presentation/widgets/login_tablet_layout.dart';
import 'package:chronoapp/features/login/presentation/routes/login_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Apple layout is restricted to iPads', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final originalPlatform = debugDefaultTargetPlatformOverride;
    addTearDown(() => debugDefaultTargetPlatformOverride = originalPlatform);
    for (final platform in [
      TargetPlatform.iOS,
      TargetPlatform.android,
      TargetPlatform.macOS,
    ]) {
      debugDefaultTargetPlatformOverride = platform;
      for (final size in [const Size(1366, 1024), const Size(844, 390)]) {
        tester.view.physicalSize = size;
        bool? appleTablet;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                appleTablet = LoginTabletLayout.isAppleTablet(context);
                return const SizedBox();
              },
            ),
          ),
        );
        expect(
          appleTablet,
          platform == TargetPlatform.iOS && size.shortestSide >= 600,
        );
      }
    }
    debugDefaultTargetPlatformOverride = originalPlatform;
  });

  testWidgets('tablet has no carousel in either orientation or split view', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1366, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [
      const Size(1366, 1024),
      const Size(1024, 1366),
      const Size(500, 1024),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: size),
            child: const LoginSplitScreen(child: Text('Login content')),
          ),
        ),
      );
      expect(find.byType(LoginPhotoCarousel), findsNothing);
      expect(find.text('Login content'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('tablet frame adapts to landscape, portrait and large text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [
      const Size(1366, 1024),
      const Size(1024, 1366),
      const Size(900, 600),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: const TextScaler.linear(1.5),
            ),
            child: const Scaffold(
              body: LoginTabletFrame(
                location: LoginPaths.notificationsIntro,
                child: Center(child: Text('Current step')),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Current step'), findsOneWidget);
      expect(find.text('Auf dem Laufenden'), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });
}
