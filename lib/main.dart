import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inspire_blur/inspire_blur.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:powersync/powersync.dart' hide Column;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/auth/supabase_auth_deep_links.dart';
import 'core/push/firebase_messaging_background.dart';
import 'core/push/push_notification_bootstrap.dart';
import 'core/push/push_notification_service.dart';
import 'firebase_options.dart';
import 'core/database/calendar_events_debug_log.dart';
import 'core/database/database_provider.dart';
import 'core/database/powersync_auth_binding.dart';
import 'core/network/connectivity_notifier.dart';
import 'core/router/app_router.dart';
import 'core/database/powersync_schema.dart';
import 'core/startup/calendar_filter_startup_state.dart';
import 'core/startup/calendar_startup_state.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'features/calendar/presentation/providers/calendar_view_options.dart';
import 'features/login/presentation/providers/profile_gate_notifier.dart';
import 'features/login/presentation/providers/profile_gate_provider.dart';

const String kSupabaseUrl = 'https://chrbvfaknykaycwumuba.supabase.co';
const String kSupabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNocmJ2ZmFrbnlrYXljd3VtdWJhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ4OTQ0MjEsImV4cCI6MjA5MDQ3MDQyMX0.K7ChUbeWNd_-wCWCswo0b-dVpe50x57qK-dsBkN9NrE';

Future<void> _initializeFirebaseCore() async {
  if (!DefaultFirebaseOptions.isConfigured) return;
  if (!PushNotificationService.supportsPush) return;

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

Future<void> _registerPushListeners() async {
  if (!DefaultFirebaseOptions.isConfigured) return;
  if (!PushNotificationService.supportsPush) return;

  try {
    await PushNotificationService().registerListeners();
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('[FCM] Push listener registration failed: $e\n$st');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Inspire.warmUp();

  await _initializeFirebaseCore();

  final results = await Future.wait<Object>([
    Supabase.initialize(url: kSupabaseUrl, anonKey: kSupabaseAnonKey),
    initializeDatabase(),
    bootstrapThemeMode(),
    bootstrapCalendarViewMode(),
  ]);
  final powerSyncDb = results[1] as PowerSyncDatabase;

  await _registerPushListeners();

  attachCalendarEventsDebugLogs(powerSyncDb);
  scheduleCalendarEventsLocalSnapshots(powerSyncDb);

  final startupNotifier = AppStartupNotifier();
  final authSessionNotifier = AuthSessionNotifier();
  final connectivityNotifier = ConnectivityNotifier();
  final profileGateNotifier = ProfileGateNotifier(localDb: powerSyncDb);

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
        connectivityNotifier: connectivityNotifier,
      ),
    ),
  );

  unawaited(PowerSyncAuthBinding.start(powerSyncDb));
  await _finishStartup(
    startupNotifier: startupNotifier,
    profileGateNotifier: profileGateNotifier,
    powerSyncDb: powerSyncDb,
  );
}

/// Ladescreen bleibt, bis Theme, Locale, Kalender-Scroll und Profil-Gate bereit sind.
Future<String?> _loadLocalProfileDiet(
  PowerSyncDatabase db,
  String userId,
) async {
  try {
    final row = await db.getOptional(
      'SELECT diet FROM $kProfilesTable WHERE id = ? LIMIT 1',
      [userId],
    );
    if (row == null) return null;
    final diet = row['diet']?.toString().trim();
    if (diet == null || diet.isEmpty) return null;
    return diet;
  } catch (_) {
    return null;
  }
}

Future<void> _finishStartup({
  required AppStartupNotifier startupNotifier,
  required ProfileGateNotifier profileGateNotifier,
  required PowerSyncDatabase powerSyncDb,
}) async {
  final view = PlatformDispatcher.instance.views.first;
  final pixelRatio = view.devicePixelRatio;
  final logicalSize = Size(
    view.physicalSize.width / pixelRatio,
    view.physicalSize.height / pixelRatio,
  );
  CalendarStartupState.preload(
    logicalScreenSize: logicalSize,
    viewMode: bootstrappedCalendarViewModeOrDefault(),
  );

  await Future.wait<void>([
    initializeDateFormatting('de', null),
    attachSupabaseAuthDeepLinks(),
    profileGateNotifier.waitUntilReady(),
  ]);

  final gateData = profileGateNotifier.data;
  if (gateData.hasSession) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final diet = userId == null
        ? null
        : await _loadLocalProfileDiet(powerSyncDb, userId);
    CalendarFilterStartupState.preload(gateData: gateData, diet: diet);
  }

  PushNotificationBootstrap.start(profileGate: profileGateNotifier);

  startupNotifier.setReady();
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({
    super.key,
    required this.startupNotifier,
    required this.authSessionNotifier,
    required this.profileGateNotifier,
    required this.connectivityNotifier,
  });

  final AppStartupNotifier startupNotifier;
  final AuthSessionNotifier authSessionNotifier;
  final ProfileGateNotifier profileGateNotifier;
  final ConnectivityNotifier connectivityNotifier;

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final AppRouter _appRouter = AppRouter(
    startupNotifier: widget.startupNotifier,
    authSessionNotifier: widget.authSessionNotifier,
    profileGateNotifier: widget.profileGateNotifier,
    connectivityNotifier: widget.connectivityNotifier,
  );

  @override
  void dispose() {
    unawaited(PushNotificationBootstrap.disposeInstance());
    PowerSyncAuthBinding.dispose();
    widget.authSessionNotifier.dispose();
    widget.profileGateNotifier.dispose();
    widget.connectivityNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(appThemeModeProvider);
    return MaterialApp.router(
      title: 'Chrono',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: _appRouter.router,
    );
  }
}
