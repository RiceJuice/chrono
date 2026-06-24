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

/// Zeigt ausstehende Eltern-Verknüpfungsanfragen für Schüler und Admins.
class GuardianLinkBootstrap {
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
    _profileGate.addListener(_onProfileGateChanged);
    _deferredPushQueue.transferAllTo(_pushQueue);
    _onProfileGateChanged();
    unawaited(_processQueue());
  }

  final ProfileGateNotifier _profileGate;
  final GlobalKey<NavigatorState> _navigatorKey;
  final GuardianLinkRepository _guardianLinks;
  final SupabaseClient _supabase;
  final GuardianLinkPushQueue _pushQueue;
  final GuardianLinkPushQueue _deferredPushQueue;

  StreamSubscription<List<GuardianChildLink>>? _linksSub;
  final List<GuardianChildLink> _queue = [];
  bool _dialogOpen = false;
  int _navigatorRetryCount = 0;

  static const int _maxNavigatorRetries = 5;
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

  void _onProfileGateChanged() {
    if (!_profileGate.isReady || !_profileGate.data.hasSession) {
      unawaited(_linksSub?.cancel());
      _linksSub = null;
      return;
    }

    final role = _profileGate.data.role?.trim();
    if (role != LoginFlowRoleIds.student && role != ProfileRoleIds.admin) {
      unawaited(_linksSub?.cancel());
      _linksSub = null;
      return;
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _linksSub ??= _guardianLinks.watchPendingForChild(userId).listen((links) {
      _queue
        ..clear()
        ..addAll(links);
      unawaited(_processQueue());
    });
  }

  Future<void> _processQueue() async {
    if (_dialogOpen) return;

    final context = _navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      if (_hasWork() && _navigatorRetryCount < _maxNavigatorRetries) {
        _navigatorRetryCount++;
        final delayMs = 200 * _navigatorRetryCount;
        unawaited(
          Future<void>.delayed(
            Duration(milliseconds: delayMs),
            _processQueue,
          ),
        );
      }
      return;
    }
    _navigatorRetryCount = 0;

    final pushPayload = _pushQueue.peek();
    GuardianChildLink? link;
    if (pushPayload != null) {
      link = await _guardianLinks.fetchLinkById(pushPayload.linkId);
      if (link == null || !link.isPending) {
        _pushQueue.remove(pushPayload.linkId);
      }
    }
    link ??= _queue.isNotEmpty ? _queue.first : null;
    if (link == null || !link.isPending) return;

    final guardianNameOverride = pushPayload?.guardianName;
    if (pushPayload != null) {
      _pushQueue.remove(pushPayload.linkId);
    }

    final dialogContext = _navigatorKey.currentContext;
    if (dialogContext == null || !dialogContext.mounted) {
      if (pushPayload != null) {
        _pushQueue.enqueue(pushPayload);
      }
      if (_navigatorRetryCount < _maxNavigatorRetries) {
        _navigatorRetryCount++;
        unawaited(
          Future<void>.delayed(
            Duration(milliseconds: 200 * _navigatorRetryCount),
            _processQueue,
          ),
        );
      }
      return;
    }

    _dialogOpen = true;
    try {
      final linkForDialog = link;
      final accept = await showGuardianLinkConfirmDialog(
        dialogContext,
        link: linkForDialog,
        guardianNameOverride: guardianNameOverride,
      );
      if (accept == null) return;

      await _guardianLinks.respondToLink(
        linkId: linkForDialog.id,
        accept: accept,
      );

      final toastContext = _navigatorKey.currentContext;
      if (toastContext == null || !toastContext.mounted) return;
      showAppToast(
        toastContext,
        accept ? 'Verknüpfung bestätigt.' : 'Verknüpfung abgelehnt.',
        kind: accept ? AppToastKind.success : AppToastKind.info,
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

  bool _hasWork() => _queue.isNotEmpty || !_pushQueue.isEmpty;

  void dispose() {
    _profileGate.removeListener(_onProfileGateChanged);
    unawaited(_linksSub?.cancel());
    _linksSub = null;
  }
}
