import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:chronoapp/core/router/app_router.dart';
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
      MyApp(
        startupNotifier: AppStartupNotifier(),
        authSessionNotifier: AuthSessionNotifier(),
      ),
    );
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
