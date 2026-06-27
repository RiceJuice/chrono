import 'dart:async';

import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:chronoapp/features/login/data/guardian_link_repository.dart';
import 'package:chronoapp/features/login/domain/models/guardian_child_link.dart';
import 'package:chronoapp/core/auth/profile_role_ids.dart';
import 'package:chronoapp/features/login/domain/models/login_flow_role_ids.dart';
import 'package:chronoapp/features/login/presentation/providers/profile_gate_notifier.dart';
import 'package:chronoapp/features/login/presentation/services/guardian_link_push_queue.dart';
import 'package:chronoapp/features/login/presentation/widgets/guardian_link_confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fügt ausstehende Links in [queue] ein oder entfernt nicht mehr pending Einträge.
@visibleForTesting
List<GuardianChildLink> mergePendingGuardianLinks(
  List<GuardianChildLink> queue,
  Iterable<GuardianChildLink> incoming,
) {
  final merged = List<GuardianChildLink>.from(queue);
  for (final link in incoming) {
    merged.removeWhere((existing) => existing.id == link.id);
    if (link.isPending) {
      merged.add(link);
    }
  }
  return merged;
}

/// Zeigt ausstehende Eltern-Verknüpfungsanfragen für Schüler und Admins.
class GuardianLinkBootstrap with WidgetsBindingObserver {
  GuardianLinkBootstrap({
    required ProfileGateNotifier profileGate,
    required GlobalKey<NavigatorState> navigatorKey,
    required GuardianLinkRepository guardianLinkRepository,
    SupabaseClient? supabase,
    GuardianLinkPushQueue? pushQueue,
    GuardianLinkPushQueue? deferredPushQueue,
  })  : _profileGate = profileGate,
        _navigatorKey = navigatorKey,
        _guardianLinks = guardianLinkRepository,
        _supabase = supabase ?? Supabase.instance.client,
        _pushQueue = pushQueue ?? GuardianLinkPushQueue(),
        _deferredPushQueue = deferredPushQueue ?? _sharedDeferredPushQueue {
    WidgetsBinding.instance.addObserver(this);
    _profileGate.addListener(_onProfileGateChanged);
    _deferredPushQueue.transferAllTo(_pushQueue);
    _onProfileGateChanged();
    unawaited(_refreshPendingFromRemote());
    unawaited(_processQueue());
  }

  final ProfileGateNotifier _profileGate;
  final GlobalKey<NavigatorState> _navigatorKey;
  final GuardianLinkRepository _guardianLinks;
  final SupabaseClient _supabase;
  final GuardianLinkPushQueue _pushQueue;
  final GuardianLinkPushQueue _deferredPushQueue;

  StreamSubscription<List<GuardianChildLink>>? _linksSub;
  Timer? _pollTimer;
  final List<GuardianChildLink> _queue = [];
  bool _dialogOpen = false;
  int _navigatorRetryCount = 0;
  bool _refreshInFlight = false;

  static const int _maxNavigatorRetryDelayMs = 5000;
  static GuardianLinkBootstrap? _instance;
  static final GuardianLinkPushQueue _sharedDeferredPushQueue =
      GuardianLinkPushQueue();

  static void start({
    required ProfileGateNotifier profileGate,
    required GlobalKey<NavigatorState> navigatorKey,
    required GuardianLinkRepository guardianLinkRepository,
  }) {
    _instance?.dispose();
    _instance = GuardianLinkBootstrap(
      profileGate: profileGate,
      navigatorKey: navigatorKey,
      guardianLinkRepository: guardianLinkRepository,
    );
  }

  static void disposeInstance() {
    _instance?.dispose();
    _instance = null;
  }

  static void handlePushPayload(Map<String, String> data) {
    final type = data['type'];
    if (type == 'guardian_link_request') {
      final linkId = data['link_id']?.trim();
      if (linkId == null || linkId.isEmpty) return;
      final guardianName = data['guardian_name']?.trim();
      final payload = GuardianLinkPushPayload(
        linkId: linkId,
        guardianName: guardianName?.isNotEmpty == true ? guardianName : null,
      );
      final instance = _instance;
      if (instance != null) {
        instance._pushQueue.enqueue(payload);
        instance._navigatorRetryCount = 0;
        unawaited(instance._processQueue());
      } else {
        _sharedDeferredPushQueue.enqueue(payload);
      }
      return;
    }
    if (type == 'guardian_link_confirmed' || type == 'guardian_link_rejected') {
      unawaited(_instance?._profileGate.refresh());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshPendingFromRemote());
    }
  }

  void _onProfileGateChanged() {
    if (!_profileGate.isReady || !_profileGate.data.hasSession) {
      unawaited(_linksSub?.cancel());
      _linksSub = null;
      _pollTimer?.cancel();
      _pollTimer = null;
      return;
    }

    final role = _profileGate.data.role?.trim();
    if (role != LoginFlowRoleIds.student && role != ProfileRoleIds.admin) {
      unawaited(_linksSub?.cancel());
      _linksSub = null;
      _pollTimer?.cancel();
      _pollTimer = null;
      return;
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _pollTimer ??= Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(_refreshPendingFromRemote()),
    );

    _linksSub ??= _guardianLinks.watchPendingForChild(userId).listen((links) {
      final merged = mergePendingGuardianLinks(_queue, links);
      _queue
        ..clear()
        ..addAll(merged);
      unawaited(_processQueue());
    });
    unawaited(_refreshPendingFromRemote());
    unawaited(_processQueue());
  }

  Future<void> _refreshPendingFromRemote() async {
    if (_refreshInFlight) return;
    if (!_profileGate.isReady || !_profileGate.data.hasSession) return;

    final role = _profileGate.data.role?.trim();
    if (role != LoginFlowRoleIds.student && role != ProfileRoleIds.admin) {
      return;
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _refreshInFlight = true;
    try {
      final pending = await _guardianLinks.loadPendingLinksForChild(userId);
      if (pending.isNotEmpty) {
        _queue
          ..clear()
          ..addAll(mergePendingGuardianLinks(_queue, pending));
        _navigatorRetryCount = 0;
      }
      if (_hasWork()) {
        unawaited(_processQueue());
      }
    } catch (_) {
      if (_hasWork()) {
        unawaited(_processQueue());
      }
    } finally {
      _refreshInFlight = false;
    }
  }

  Future<void> _processQueue() async {
    if (_dialogOpen) return;

    final context = _navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      if (_hasWork()) {
        _scheduleNavigatorRetry();
      }
      return;
    }
    _navigatorRetryCount = 0;

    final pushPayload = _pushQueue.peek();
    GuardianChildLink? link;
    GuardianLinkPushPayload? resolvedPushPayload;

    if (pushPayload != null) {
      link = await _guardianLinks.fetchLinkById(pushPayload.linkId);
      if (link == null) {
        _scheduleProcessRetry();
        return;
      }
      if (!link.isPending) {
        _pushQueue.remove(pushPayload.linkId);
        link = null;
      } else {
        resolvedPushPayload = pushPayload;
      }
    }

    link ??= _queue.isNotEmpty ? _queue.first : null;
    if (link == null || !link.isPending) return;

    final guardianNameOverride = resolvedPushPayload?.guardianName;
    if (resolvedPushPayload != null) {
      _pushQueue.remove(resolvedPushPayload.linkId);
    }

    final dialogContext = _navigatorKey.currentContext;
    if (dialogContext == null || !dialogContext.mounted) {
      if (resolvedPushPayload != null) {
        _pushQueue.enqueue(resolvedPushPayload);
      }
      _scheduleNavigatorRetry();
      return;
    }

    _dialogOpen = true;
    try {
      final linkForDialog = link;
      final result = await showGuardianLinkConfirmDialog(
        dialogContext,
        link: linkForDialog,
        guardianNameOverride: guardianNameOverride,
      );
      if (result == null || result.accept == null) return;

      await _guardianLinks.respondToLink(
        linkId: linkForDialog.id,
        accept: result.accept!,
        sharePermissions: result.sharePermissions,
      );

      final toastContext = _navigatorKey.currentContext;
      if (toastContext == null || !toastContext.mounted) return;
      showAppToast(
        toastContext,
        result.accept!
            ? 'Verknüpfung bestätigt.'
            : 'Verknüpfung abgelehnt.',
        kind: result.accept!
            ? AppToastKind.success
            : AppToastKind.info,
      );

      _queue.removeWhere((l) => l.id == linkForDialog.id);
    } catch (_) {
      final toastContext = _navigatorKey.currentContext;
      if (toastContext != null && toastContext.mounted) {
        showAppToast(
          toastContext,
          'Antwort konnte nicht gespeichert werden.',
          kind: AppToastKind.error,
        );
      }
    } finally {
      _dialogOpen = false;
      if (_hasWork()) {
        unawaited(
          Future<void>.delayed(
            const Duration(milliseconds: 300),
            _processQueue,
          ),
        );
      }
    }
  }

  void _scheduleNavigatorRetry() {
    if (!_hasWork()) return;
    _navigatorRetryCount++;
    final delayMs = (200 * _navigatorRetryCount).clamp(
      200,
      _maxNavigatorRetryDelayMs,
    );
    unawaited(
      Future<void>.delayed(
        Duration(milliseconds: delayMs),
        _processQueue,
      ),
    );
  }

  void _scheduleProcessRetry() {
    if (!_hasWork()) return;
    _navigatorRetryCount++;
    final delayMs = (200 * _navigatorRetryCount).clamp(
      200,
      _maxNavigatorRetryDelayMs,
    );
    unawaited(
      Future<void>.delayed(
        Duration(milliseconds: delayMs),
        _processQueue,
      ),
    );
  }

  bool _hasWork() => _queue.isNotEmpty || !_pushQueue.isEmpty;

  static void requestProcessQueue() {
    final instance = _instance;
    if (instance == null) return;
    unawaited(instance._refreshPendingFromRemote());
    unawaited(instance._processQueue());
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _profileGate.removeListener(_onProfileGateChanged);
    _pollTimer?.cancel();
    _pollTimer = null;
    unawaited(_linksSub?.cancel());
    _linksSub = null;
  }
}
