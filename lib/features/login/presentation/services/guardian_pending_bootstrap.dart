import 'dart:async';

import 'package:chronoapp/core/auth/profile_role_ids.dart';
import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:chronoapp/features/login/data/guardian_link_repository.dart';
import 'package:chronoapp/features/login/domain/models/guardian_child_link.dart';
import 'package:chronoapp/features/login/domain/models/login_flow_role_ids.dart';
import 'package:chronoapp/features/login/presentation/providers/profile_gate_notifier.dart';
import 'package:chronoapp/features/login/presentation/routes/login_paths.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Prüft für Eltern beim App-Start und bei Resume ausstehende/bestätigte
/// Kind-Verknüpfungen — unabhängig von Push-Benachrichtigungen.
class GuardianPendingBootstrap with WidgetsBindingObserver {
  GuardianPendingBootstrap({
    required ProfileGateNotifier profileGate,
    required GlobalKey<NavigatorState> navigatorKey,
    required GuardianLinkRepository guardianLinkRepository,
    SupabaseClient? supabase,
  })  : _profileGate = profileGate,
        _navigatorKey = navigatorKey,
        _guardianLinks = guardianLinkRepository,
        _supabase = supabase ?? Supabase.instance.client {
    _profileGate.addListener(_onProfileGateChanged);
    WidgetsBinding.instance.addObserver(this);
    _onProfileGateChanged();
  }

  final ProfileGateNotifier _profileGate;
  final GlobalKey<NavigatorState> _navigatorKey;
  final GuardianLinkRepository _guardianLinks;
  final SupabaseClient _supabase;

  StreamSubscription<List<GuardianChildLink>>? _linksSub;
  Timer? _pollTimer;
  bool _checking = false;

  static GuardianPendingBootstrap? _instance;

  static void start({
    required ProfileGateNotifier profileGate,
    required GlobalKey<NavigatorState> navigatorKey,
    required GuardianLinkRepository guardianLinkRepository,
  }) {
    _instance?.dispose();
    _instance = GuardianPendingBootstrap(
      profileGate: profileGate,
      navigatorKey: navigatorKey,
      guardianLinkRepository: guardianLinkRepository,
    );
  }

  static void disposeInstance() {
    _instance?.dispose();
    _instance = null;
  }

  void _onProfileGateChanged() {
    if (!_profileGate.isReady || !_profileGate.data.hasSession) {
      _stopWatching();
      return;
    }

    final role = _profileGate.data.role?.trim();
    if (role != LoginFlowRoleIds.guardian && role != ProfileRoleIds.admin) {
      _stopWatching();
      return;
    }

    _startWatching();
    unawaited(_checkConfirmationStatus());
  }

  void _startWatching() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _pollTimer ??= Timer.periodic(
      const Duration(seconds: 8),
      (_) => unawaited(_checkConfirmationStatus()),
    );

    _linksSub ??= _guardianLinks.watchLinksForUser(userId).listen((links) {
      if (links.any((l) => l.isConfirmed)) {
        unawaited(_checkConfirmationStatus());
      }
    });
  }

  void _stopWatching() {
    unawaited(_linksSub?.cancel());
    _linksSub = null;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _checkConfirmationStatus() async {
    if (_checking) return;
    if (!_profileGate.isReady || !_profileGate.data.hasSession) return;

    final role = _profileGate.data.role?.trim();
    if (role != LoginFlowRoleIds.guardian && role != ProfileRoleIds.admin) {
      return;
    }

    _checking = true;
    try {
      final confirmed = await _guardianLinks.tryApplyConfirmedLink();
      if (confirmed == null) return;

      await _profileGate.refresh();

      final context = _navigatorKey.currentContext;
      if (context == null || !context.mounted) return;

      if (_profileGate.data.isOnboardingComplete) return;

      showAppToast(
        context,
        '${confirmed.childDisplayName} hat die Verknüpfung bestätigt.',
        kind: AppToastKind.success,
      );
      context.go(LoginPaths.success);
    } catch (_) {
      // Polling ist best-effort.
    } finally {
      _checking = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkConfirmationStatus());
    }
  }

  void dispose() {
    _profileGate.removeListener(_onProfileGateChanged);
    WidgetsBinding.instance.removeObserver(this);
    _stopWatching();
  }
}
