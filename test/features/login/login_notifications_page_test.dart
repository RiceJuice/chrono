import 'dart:async';

import 'package:chronoapp/features/login/presentation/pages/notifications/login_notifications_page.dart';
import 'package:chronoapp/features/login/presentation/routes/login_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<GoRouter> showFlow(
    WidgetTester tester, {
    required Future<void> Function() request,
  }) async {
    final router = GoRouter(
      initialLocation: LoginPaths.notificationsIntro,
      routes: [
        GoRoute(
          path: LoginPaths.notificationsIntro,
          builder: (_, _) =>
              const Scaffold(body: SafeArea(child: LoginNotificationsPage())),
        ),
        GoRoute(
          path: LoginPaths.notificationsPermission,
          builder: (_, _) => Scaffold(
            body: SafeArea(
              child: LoginNotificationsPage(
                requestStep: true,
                requestPermission: request,
              ),
            ),
          ),
        ),
        GoRoute(
          path: LoginPaths.success,
          builder: (_, _) => const Scaffold(body: Text('Alles bereit!')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets(
    'permission is requested only by button; repeated taps are blocked',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final haptics = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      var requests = 0;
      final completion = Completer<void>();
      await showFlow(
        tester,
        request: () {
          requests++;
          return completion.future;
        },
      );
      expect(requests, 0);
      await tester.tap(find.byTooltip('Weiter zu Mitteilungen'));
      await tester.pumpAndSettle();
      expect(haptics, contains('HapticFeedbackType.lightImpact'));
      expect(requests, 0);
      await tester.tap(find.text('Mitteilungen erlauben'));
      await tester.pump();
      expect(requests, 1);
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, 'Vielleicht später'),
            )
            .onPressed,
        isNull,
      );
      completion.complete();
      await tester.pumpAndSettle();
      expect(find.text('Alles bereit!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'small screen and large text stay scrollable; skipping never requests permission',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      var requests = 0;
      await showFlow(
        tester,
        request: () async {
          requests++;
        },
      );
      await tester.ensureVisible(find.byTooltip('Weiter zu Mitteilungen'));
      await tester.tap(find.byTooltip('Weiter zu Mitteilungen'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Vielleicht später'));
      await tester.tap(find.text('Vielleicht später'));
      await tester.pumpAndSettle();
      expect(requests, 0);
      expect(find.text('Alles bereit!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
