import 'dart:async';

import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:chronoapp/features/login/data/guardian_link_repository.dart';
import 'package:chronoapp/features/login/domain/models/guardian_child_link.dart';
import 'package:chronoapp/core/auth/profile_role_ids.dart';
import 'package:chronoapp/features/login/domain/models/login_flow_role_ids.dart';
import 'package:chronoapp/features/login/presentation/providers/profile_gate_notifier.dart';
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
  })  : _profileGate = profileGate,
        _navigatorKey = navigatorKey,
        _guardianLinks = guardianLinkRepository,
        _supabase = supabase ?? Supabase.instance.client {
    _profileGate.addListener(_onProfileGateChanged);
    _onProfileGateChanged();
  }

  final ProfileGateNotifier _profileGate;
  final GlobalKey<NavigatorState> _navigatorKey;
  final GuardianLinkRepository _guardianLinks;
  final SupabaseClient _supabase;

  StreamSubscription<List<GuardianChildLink>>? _linksSub;
  final List<GuardianChildLink> _queue = [];
  bool _dialogOpen = false;
  String? _pendingLinkIdFromPush;

  static GuardianLinkBootstrap? _instance;

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
      _instance?._pendingLinkIdFromPush = linkId;
      unawaited(_instance?._processQueue());
      return;
    }
    if (type == 'guardian_link_confirmed') {
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
    if (context == null || !context.mounted) return;

    GuardianChildLink? link;
    if (_pendingLinkIdFromPush != null) {
      link = await _guardianLinks.fetchLinkById(_pendingLinkIdFromPush!);
      _pendingLinkIdFromPush = null;
    }
    link ??= _queue.isNotEmpty ? _queue.first : null;
    if (link == null || !link.isPending) return;

    _dialogOpen = true;
    try {
      final linkForDialog = link;
      final accept =
          await showGuardianLinkConfirmDialog(context, link: linkForDialog);
      if (accept == null) return;

      await _guardianLinks.respondToLink(linkId: linkForDialog.id, accept: accept);

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
      if (_queue.isNotEmpty || _pendingLinkIdFromPush != null) {
        unawaited(Future<void>.delayed(
          const Duration(milliseconds: 300),
          _processQueue,
        ));
      }
    }
  }

  void dispose() {
    _profileGate.removeListener(_onProfileGateChanged);
    unawaited(_linksSub?.cancel());
    _linksSub = null;
  }
}
