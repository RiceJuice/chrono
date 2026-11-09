import 'dart:io';
import 'package:chronoapp/features/login/presentation/widgets/login_start_auth_panel.dart';
import 'package:chronoapp/features/login/presentation/widgets/login_flow_body.dart';

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoapp/features/login/presentation/widgets/login_split_screen.dart';
import 'package:chronoapp/features/login/presentation/widgets/login_photo_carousel.dart';

void main() {
  testWidgets('wide desktop layouts show photos and advance smoothly', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [const Size(768, 580), const Size(1024, 580)]) {
      tester.view.physicalSize = size;
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: key,
            child: const Scaffold(
              body: LoginSplitScreen(
                child: LoginFlowBody(
                  location: '/login',
                  fillViewport: true,
                  pinBottomBarToEdge: true,
                  bottomBar: LoginStartAuthPanel(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Chrono',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Chorplanung und Termine an einem Ort.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();
      expect(find.byType(LoginPhotoCarousel), findsOneWidget);
      Future<void> capture(String suffix) async {
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '/private/tmp/login-${size.width.toInt()}-$suffix.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await capture('first');
      await tester.pump(const Duration(seconds: 6));
      await tester.pump(const Duration(milliseconds: 700));
      await capture('transition');
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byKey(const ValueKey(1)), findsOneWidget);
      await capture('second');
      for (final next in [2, 3, 4, 5, 0]) {
        await tester.pump(const Duration(seconds: 6));
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump(const Duration(milliseconds: 1400));
        expect(find.byKey(ValueKey(next)), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
  });
}
