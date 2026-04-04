import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/database/calendar_events_debug_log.dart';
import 'core/database/database_provider.dart';
import 'core/database/powersync_auth_binding.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';


const String _defaultSupabaseUrl = 'https://chrbvfaknykaycwumuba.supabase.co';
const String _defaultSupabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNocmJ2ZmFrbnlrYXljd3VtdWJhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ4OTQ0MjEsImV4cCI6MjA5MDQ3MDQyMX0.K7ChUbeWNd_-wCWCswo0b-dVpe50x57qK-dsBkN9NrE';

const String _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: _defaultSupabaseUrl,
);
const String _supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: _defaultSupabaseAnonKey,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Supabase & DB Setup
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  final powerSyncDb = await initializeDatabase();
  attachCalendarEventsDebugLogs(powerSyncDb);
  scheduleCalendarEventsLocalSnapshots(powerSyncDb);
  await PowerSyncAuthBinding.start(powerSyncDb);

  final startupNotifier = AppStartupNotifier();
  final authSessionNotifier = AuthSessionNotifier();

  runApp(
    ProviderScope(
      overrides: [
        dbProvider.overrideWithValue(powerSyncDb),
      ],
      child: MyApp(
        startupNotifier: startupNotifier,
        authSessionNotifier: authSessionNotifier,
      ),
    ),
  );

  // Initialisierungs-Logik (parallel zum App-Start)
  await initializeDateFormatting('de', null);
  await Future.delayed(const Duration(seconds: 2));
  startupNotifier.setReady();
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    required this.startupNotifier,
    required this.authSessionNotifier,
  });

  final AppStartupNotifier startupNotifier;
  final AuthSessionNotifier authSessionNotifier;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppRouter _appRouter = AppRouter(
    startupNotifier: widget.startupNotifier,
    authSessionNotifier: widget.authSessionNotifier,
  );

  @override
  void dispose() {
    PowerSyncAuthBinding.dispose();
    widget.authSessionNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Chrono',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _appRouter.router,
    );
  }
}