import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:chronoapp/core/theme/app_theme.dart';
import 'package:chronoapp/core/auth/auth_user_id_provider.dart';
import 'package:chronoapp/features/login/domain/models/guardian_child_link.dart';
import 'package:chronoapp/features/login/domain/models/guardian_child_share_permissions.dart';
import 'package:chronoapp/features/login/domain/models/profile_gate_data.dart';
import 'package:chronoapp/features/login/presentation/providers/guardian_link_providers.dart';
import 'package:chronoapp/features/login/presentation/providers/profile_gate_provider.dart';
import 'package:chronoapp/features/login/presentation/state/login_flow_draft.dart';
import 'package:chronoapp/features/login/presentation/routes/login_routes.dart';
import 'package:chronoapp/features/login/presentation/widgets/guardian_link_confirm_dialog.dart';
import 'package:chronoapp/features/settings/presentation/widgets/guardian_parent_access_section.dart';

const pending = GuardianChildLink(
  id: 'link',
  guardianId: 'parent',
  childId: 'child',
  status: 'pending',
  guardianFirstName: 'Alex',
  guardianLastName: 'Beispiel',
  childFirstName: 'Robin',
  childLastName: 'Beispiel',
);
void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final loader = FontLoader('LibreBaskerville');
    loader.addFont(rootBundle.load('assets/fonts/LibreBaskerville-Bold.ttf'));
    await loader.load();
    final fonts =
        '${File(Platform.resolvedExecutable).parent.parent.parent.path}/material_fonts';
    final sans = FontLoader('Roboto');
    for (final file in [
      'Roboto-Regular.ttf',
      'Roboto-Medium.ttf',
      'Roboto-Bold.ttf',
    ]) {
      sans.addFont(
        File(
          '$fonts/$file',
        ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
      );
    }
    await sans.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(
        File(
          '$fonts/MaterialIcons-Regular.otf',
        ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
      );
    await icons.load();
  });
  Future<void> size(WidgetTester t, Size size) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = size;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
  }

  Future<void> capture(WidgetTester t, GlobalKey key, String name) async {
    await t.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = Directory('/private/tmp/chrono-guardian-preview');
      await dir.create(recursive: true);
      await File(
        '${dir.path}/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets(
    'actual guardian route retains waiting status and gates Continue',
    (t) async {
      await size(t, const Size(390, 844));
      LoginFlowDraft.instance.role = 'Elternteil';
      final stream = StreamController<List<GuardianChildLink>>();
      addTearDown(stream.close);
      final router = GoRouter(
        initialLocation: LoginPaths.guardianPending,
        routes: loginRoutes,
      );
      addTearDown(router.dispose);
      final key = GlobalKey();
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            authUserIdProvider.overrideWith((ref) => Stream.value('parent')),
            guardianLinksProvider.overrideWith((ref) => stream.stream),
          ],
          child: RepaintBoundary(
            key: key,
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.dark,
              routerConfig: router,
            ),
          ),
        ),
      );
      stream.add([pending]);
      await t.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        LoginPaths.selectChild,
      );
      expect(find.text('Bestätigung ausstehend'), findsOneWidget);
      expect(find.text('Weiter'), findsNothing);
      await capture(t, key, 'parent-pending');
      stream.add([pending.copyWithStatus('confirmed')]);
      await t.pumpAndSettle();
      expect(find.text('Weiter'), findsOneWidget);
      expect(
        find.text('Verbunden. Dein Kind teilt derzeit keine Inhalte.'),
        findsOneWidget,
      );
      stream.addError(StateError('offline'));
      await t.pumpAndSettle();
      expect(
        find.textContaining('Status konnte nicht aktualisiert'),
        findsOneWidget,
      );
      expect(find.text('Weiter'), findsNothing);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'sheet retains choices on failure and blocks duplicate submissions',
    (t) async {
      await size(t, const Size(390, 844));
      final key = GlobalKey();
      var calls = 0;
      var save = Completer<void>();
      await t.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showGuardianLinkConfirmDialog(
                    context,
                    link: pending,
                    onSubmit: (result) {
                      calls++;
                      return save.future;
                    },
                  ),
                  child: const Text('Öffnen'),
                ),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('Öffnen'));
      await t.pumpAndSettle();
      expect(find.text('Nicht verknüpfen'), findsOneWidget);
      expect(find.text('Später'), findsOneWidget);
      expect(
        t
            .widgetList<SwitchListTile>(find.byType(SwitchListTile))
            .every((w) => !w.value),
        true,
      );
      await t.tap(find.text('Stundenplan'));
      await t.pumpAndSettle();
      await capture(t, key, 'child-request');
      await t.ensureVisible(find.text('Verknüpfen'));
      await t.tap(find.text('Verknüpfen'));
      await t.pump();
      await t.tap(find.text('Wird gespeichert …'));
      await t.pump();
      expect(calls, 1);
      save.completeError(StateError('offline'));
      await t.pumpAndSettle();
      expect(
        find.textContaining('Deine Auswahl bleibt erhalten'),
        findsOneWidget,
      );
      expect(
        t.widget<SwitchListTile>(find.byType(SwitchListTile).first).value,
        true,
      );
      save = Completer<void>();
      await t.ensureVisible(find.text('Verknüpfen'));
      await t.tap(find.text('Verknüpfen'));
      await t.pump();
      save.complete();
      await t.pumpAndSettle();
      expect(find.text('Verknüpfungsanfrage'), findsNothing);
    },
  );
  testWidgets('consent settings show selected areas and explicit disconnect', (
    t,
  ) async {
    await size(t, const Size(390, 844));
    final key = GlobalKey();
    final link = pending
        .copyWithStatus('confirmed')
        .copyWithSharePermissions(
          const GuardianChildSharePermissions(shareSchool: true),
        );
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          authUserIdProvider.overrideWith((ref) => Stream.value('child')),
          guardianLinksProvider.overrideWith((ref) => Stream.value([link])),
          pendingGuardianLinksProvider.overrideWith((ref) => Stream.value([])),
          profileGateDataProvider.overrideWithValue(
            const ProfileGateData.signedOut().copyWith(role: 'Schüler'),
          ),
        ],
        child: RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            home: const Scaffold(
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: GuardianParentAccessSection(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Verbindung trennen'), findsOneWidget);
    expect(
      t.widget<SwitchListTile>(find.byType(SwitchListTile).first).value,
      true,
    );
    await capture(t, key, 'sharing-settings');
  });
  for (final viewport in [
    const Size(320, 568),
    const Size(768, 1024),
    const Size(1024, 768),
    const Size(507, 768),
  ]) {
    testWidgets('consent actions reachable at $viewport with large text', (
      t,
    ) async {
      await size(t, viewport);
      await t.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          home: MediaQuery(
            data: MediaQueryData(
              size: viewport,
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: GuardianLinkConfirmWalkthrough(
                guardianName: 'Alex Beispiel',
                onSubmit: (_) async {},
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      for (final label in ['Verknüpfen', 'Nicht verknüpfen', 'Später']) {
        await t.ensureVisible(find.text(label));
        await t.pumpAndSettle();
        expect(find.text(label).hitTestable(), findsOneWidget);
      }
      expect(t.takeException(), isNull);
    });
  }
}
