import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:chronoapp/core/network/connectivity_notifier.dart';
import 'package:chronoapp/core/router/app_router.dart';
import 'package:chronoapp/features/login/presentation/providers/profile_gate_notifier.dart';
import 'package:chronoapp/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-anon-key-for-widget-test',
    );
  });

  testWidgets('app builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MyApp(
          startupNotifier: AppStartupNotifier(),
          authSessionNotifier: AuthSessionNotifier(),
          profileGateNotifier: ProfileGateNotifier(),
          connectivityNotifier: ConnectivityNotifier.test(),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
