import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/guardian_link_repository.dart';
import '../../domain/models/guardian_child_link.dart';
import '../providers/profile_gate_notifier.dart';
import '../widgets/guardian_link_confirm_dialog.dart';
import '../../../../core/widgets/app_toast.dart';
import 'guardian_link_push_queue.dart';

@visibleForTesting
List<GuardianChildLink> mergePendingGuardianLinks(
  List<GuardianChildLink> queue,
  Iterable<GuardianChildLink> incoming,
) => incoming.where((l) => l.isPending).toList();

/// Sync only updates the banner. A sheet requires a tap on the banner or push.
class GuardianLinkBootstrap with WidgetsBindingObserver {
  GuardianLinkBootstrap({
    required ProfileGateNotifier profileGate,
    required GlobalKey<NavigatorState> navigatorKey,
    required GuardianLinkRepository guardianLinkRepository,
    SupabaseClient? supabase,
    GuardianLinkPushQueue? pushQueue,
    GuardianLinkPushQueue? deferredPushQueue,
  }) : _profileGate = profileGate,
       _navigatorKey = navigatorKey,
       _guardianLinks = guardianLinkRepository,
       _supabase = supabase ?? Supabase.instance.client,
       _pushQueue = pushQueue ?? GuardianLinkPushQueue() {
    (deferredPushQueue ?? _sharedDeferredPushQueue).transferAllTo(_pushQueue);
    WidgetsBinding.instance.addObserver(this);
    _profileGate.addListener(_onProfileGateChanged);
    _authSub = _supabase.auth.onAuthStateChange.listen(
      (_) => _onProfileGateChanged(),
    );
    _onProfileGateChanged();
  }
  final ProfileGateNotifier _profileGate;
  final GlobalKey<NavigatorState> _navigatorKey;
  final GuardianLinkRepository _guardianLinks;
  final SupabaseClient _supabase;
  final GuardianLinkPushQueue _pushQueue;
  StreamSubscription? _authSub;
  StreamSubscription? _linksSub;
  String? _userId;
  int _epoch = 0;
  bool _disposed = false, _processing = false, _refreshing = false;
  ValueNotifier<bool>? _sheetValid;
  bool _wasReady = false;
  bool _waitingForNavigator = false;
  int _navigatorRetries = 0;
  static GuardianLinkBootstrap? _instance;
  static final _sharedDeferredPushQueue = GuardianLinkPushQueue();

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
    _sharedDeferredPushQueue.clear();
  }

  bool _valid(int epoch, String user) =>
      !_disposed &&
      epoch == _epoch &&
      _userId == user &&
      _supabase.auth.currentUser?.id == user;

  static void handlePushPayload(Map<String, String> data) {
    final instance = _instance;
    if (data['type'] == 'guardian_link_request' && data['opened'] == 'true') {
      final id = data['link_id'];
      if (id != null && id.isNotEmpty) {
        final payload = GuardianLinkPushPayload(linkId: id);
        if (instance == null) {
          _sharedDeferredPushQueue.enqueue(payload);
        } else {
          instance._pushQueue.enqueue(payload);
          unawaited(instance._processQueue());
        }
      }
    }
    unawaited(instance?._refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  void _onProfileGateChanged() {
    if (_disposed) return;
    final user = _supabase.auth.currentUser?.id;
    if (user != _userId) {
      final hadUser = _userId != null;
      _epoch++;
      _sheetValid?.value = false;
      unawaited(_linksSub?.cancel());
      _linksSub = null;
      if (hadUser) _guardianLinks.clearSession();
      if (hadUser) {
        _pushQueue.clear();
        _sharedDeferredPushQueue.clear();
      }
      _userId = user;
      _wasReady = false;
    }
    if (user == null || !_profileGate.isReady) return;
    final becameReady = !_wasReady;
    _wasReady = true;
    final epoch = _epoch;
    _linksSub ??= _guardianLinks.watchLinksForUser(user).listen((_) {
      if (_valid(epoch, user)) unawaited(_profileGate.refresh(remote: false));
    }, onError: (Object _) {});
    if (becameReady && !_pushQueue.isEmpty) unawaited(_processQueue());
  }

  Future<void> _refresh() async {
    if (_disposed || _refreshing || _userId == null) return;
    final user = _userId!;
    final epoch = _epoch;
    _refreshing = true;
    try {
      await _guardianLinks.loadLinksRemote(user);
      if (_valid(epoch, user)) await _profileGate.refresh();
    } catch (_) {
      /* Stream/UI retains an explicit refresh error. */
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _processQueue({bool fromBanner = false}) async {
    if (_disposed || _processing || _userId == null || !_profileGate.isReady) {
      return;
    }
    if (_navigatorKey.currentContext == null) {
      if (!_waitingForNavigator && _navigatorRetries < 3) {
        _waitingForNavigator = true;
        _navigatorRetries++;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _waitingForNavigator = false;
          if (!_disposed) unawaited(_processQueue(fromBanner: fromBanner));
        });
        WidgetsBinding.instance.scheduleFrame();
      }
      return;
    }
    _navigatorRetries = 0;
    // Lock before the first fetch: push, resume and banner cannot race.
    _processing = true;
    final epoch = _epoch;
    final user = _userId!;
    try {
      final links = await _guardianLinks.loadLinksRemote(user);
      if (!_valid(epoch, user)) return;
      GuardianChildLink? selected;
      while (!_pushQueue.isEmpty) {
        final id = _pushQueue.peek()!.linkId;
        _pushQueue.remove(id);
        for (final link in links) {
          if (link.id == id && link.childId == user && link.isPending) {
            selected = link;
          }
        }
        if (selected != null) break;
      }
      if (selected == null && fromBanner) {
        for (final link in links) {
          if (link.childId == user && link.isPending) {
            selected = link;
            break;
          }
        }
      }
      if (selected == null) return;
      final context = _navigatorKey.currentContext;
      if (context == null || !context.mounted) return;
      final link = selected;
      final validity = ValueNotifier(true);
      _sheetValid = validity;
      try {
        await showGuardianLinkConfirmDialog(
          context,
          link: link,
          sessionValid: validity,
          onSubmit: (result) async {
            if (!_valid(epoch, user)) {
              throw GuardianLinkRepositoryException('Sitzung geändert.');
            }
            await _guardianLinks.respondToLink(
              linkId: link.id,
              accept: result.accept!,
              expectedRevision: link.revision,
              sharePermissions: result.sharePermissions,
            );
          },
        );
      } finally {
        if (identical(_sheetValid, validity)) _sheetValid = null;
        _pushQueue.remove(link.id);
        validity.dispose();
      }
    } catch (_) {
      final context = _navigatorKey.currentContext;
      if (_valid(epoch, user) && context != null && context.mounted) {
        showAppToast(
          context,
          'Anfrage konnte nicht geladen werden. Bitte online erneut öffnen.',
          kind: AppToastKind.error,
        );
      }
    } finally {
      _processing = false;
    }
    // No automatic reopening, retry timers or forced processing of the next child.
  }

  Future<void> openPendingRequests() => _processQueue(fromBanner: true);

  static void requestProcessQueue() {
    unawaited(_instance?._processQueue(fromBanner: true));
  }

  void dispose() {
    _disposed = true;
    _epoch++;
    _sheetValid?.value = false;
    WidgetsBinding.instance.removeObserver(this);
    _profileGate.removeListener(_onProfileGateChanged);
    unawaited(_linksSub?.cancel());
    unawaited(_authSub?.cancel());
    _pushQueue.clear();
  }
}
