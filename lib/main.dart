import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/auth/supabase_apple_auth_deep_links.dart';
import 'core/database/calendar_events_debug_log.dart';
import 'core/database/database_provider.dart';
import 'core/database/powersync_auth_binding.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/login/presentation/providers/profile_gate_notifier.dart';
import 'features/login/presentation/providers/profile_gate_provider.dart';


const String _defaultSupabaseUrl = 'https://chrbvfaknykaycwumuba.supabase.co';
const String _defaultSupabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNocmJ2ZmFrbnlrYXljd3VtdWJhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ4OTQ0MjEsImV4cCI6MjA5MDQ3MDQyMX0.K7ChUbeWNd_-wCWCswo0b-dVpe50x57qK-dsBkN9NrE';

const String _supabaseUrlFromEnv = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: '',
);
const String _supabaseAnonKeyFromEnv = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: '',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final supabaseUrl = _supabaseUrlFromEnv.trim().isEmpty
      ? _defaultSupabaseUrl
      : _supabaseUrlFromEnv.trim();
  final supabaseAnonKey = _supabaseAnonKeyFromEnv.trim().isEmpty
      ? _defaultSupabaseAnonKey
      : _supabaseAnonKeyFromEnv.trim();

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError(
      'Supabase Konfiguration fehlt. SUPABASE_URL und SUPABASE_ANON_KEY prüfen.',
    );
  }

  // 1. Supabasboard eintragen (s. core/auth/auth_redirect_config.dart).e & DB Setup
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  // iOS/macOS: Mail-Bestätigungslink → App; Redirect-URL im Supabase-Dash
  await attachSupabaseAppleAuthDeepLinks();
  final powerSyncDb = await initializeDatabase();
  attachCalendarEventsDebugLogs(powerSyncDb);
  scheduleCalendarEventsLocalSnapshots(powerSyncDb);
  await PowerSyncAuthBinding.start(powerSyncDb);

  final startupNotifier = AppStartupNotifier();
  final authSessionNotifier = AuthSessionNotifier();
  final profileGateNotifier = ProfileGateNotifier();

  runApp(
    ProviderScope(
      overrides: [
        dbProvider.overrideWithValue(powerSyncDb),
        profileGateProvider.overrideWithValue(profileGateNotifier),
      ],
      child: MyApp(
        startupNotifier: startupNotifier,
        authSessionNotifier: authSessionNotifier,
        profileGateNotifier: profileGateNotifier,
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
    required this.profileGateNotifier,
  });

  final AppStartupNotifier startupNotifier;
  final AuthSessionNotifier authSessionNotifier;
  final ProfileGateNotifier profileGateNotifier;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppRouter _appRouter = AppRouter(
    startupNotifier: widget.startupNotifier,
    authSessionNotifier: widget.authSessionNotifier,
    profileGateNotifier: widget.profileGateNotifier,
  );

  @override
  void dispose() {
    PowerSyncAuthBinding.dispose();
    widget.authSessionNotifier.dispose();
    widget.profileGateNotifier.dispose();
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