import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/calendar/presentation/pages/calendar_page.dart';
import 'core/loading_page.dart';
import 'features/login/presentation/routes/login_routes.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final _appStartup = _AppStartupNotifier();

  static final GoRouter _router = GoRouter(
    refreshListenable: _appStartup,
    initialLocation: '/loading',
    redirect: (context, state) {
      final isLoadingRoute = state.matchedLocation == '/loading';
      if (!_appStartup.isReady && !isLoadingRoute) {
        return '/loading';
      }
      if (_appStartup.isReady && isLoadingRoute) {
        return '/calendar';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (context, state) => const LoadingPage(),
      ),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const CalendarPage(),
      ),
      ...loginRoutes,
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Chrono',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}

class _AppStartupNotifier extends ChangeNotifier {
  _AppStartupNotifier() {
    _initialize();
  }

  bool isReady = false;

  Future<void> _initialize() async {
    await Future.wait([
      initializeDateFormatting('de', null),
      Future<void>.delayed(const Duration(seconds: 2)),
    ]);
    isReady = true;
    notifyListeners();
  }
}