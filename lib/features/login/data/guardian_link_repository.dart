import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/guardian_link_status.dart';

import 'package:flutter/foundation.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/profile_role_ids.dart';
import '../../../core/database/powersync_schema.dart';
import '../domain/models/guardian_child_link.dart';
import '../domain/models/guardian_child_share_permissions.dart';
import '../domain/models/login_flow_role_ids.dart';

class GuardianLinkRepositoryException implements Exception {
  GuardianLinkRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NotifyLinkResult {
  const NotifyLinkResult({
    required this.pushAccepted,
    this.sent = 0,
    this.failed = 0,
  });

  final bool pushAccepted;
  final int sent;
  final int failed;
}

class RequestLinksResult {
  const RequestLinksResult({
    required this.createdLinks,
    required this.skippedChildIds,
    required this.anyPushFailed,
    this.notifyResults = const {},
  });

  final List<GuardianChildLink> createdLinks;
  final List<String> skippedChildIds;
  final bool anyPushFailed;
  final Map<String, NotifyLinkResult> notifyResults;

  bool get hasCreatedLinks => createdLinks.isNotEmpty;
}

class GuardianLinkRequestResult {
  const GuardianLinkRequestResult({
    required this.link,
    required this.notifyResult,
  });

  final GuardianChildLink link;
  final NotifyLinkResult notifyResult;
}

class GuardianLinkRepository {
  GuardianLinkRepository(this._db, {SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final PowerSyncDatabase? _db;
  final SupabaseClient _supabase;

  final _snapshots = <String, List<GuardianChildLink>>{};
  final _changes = StreamController<String>.broadcast();
  String? get _userId => _supabase.auth.currentUser?.id;

  int _sessionEpoch = 0;
  final _requests = <String, int>{};
  final _appliedRequests = <String, int>{};
  Future<void> _cacheWrite = Future.value();
  static const _cachePrefix = 'guardian_snapshot_v1_';

  Future<void> _persist(String user, List<GuardianChildLink> links) {
    // Serialize disk writes: a delayed older write must not restore permission.
    final encoded = jsonEncode(links.map((link) => link.toRow()).toList());
    _cacheWrite = _cacheWrite
        .then((_) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('$_cachePrefix$user', encoded);
        })
        .catchError((Object _) {});
    return _cacheWrite;
  }

  Future<List<GuardianChildLink>?> _readPersisted(String user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_cachePrefix$user');
      if (raw == null) return null;
      return (jsonDecode(raw) as List)
          .map(
            (row) => GuardianChildLink.fromRow(Map<String, dynamic>.from(row)),
          )
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _accept(String user, List<GuardianChildLink> links) async {
    _snapshots[user] = links;
    _changes.add(user);
    await _persist(user, links);
  }

  Future<void> _refreshAfterCommit(String user) async {
    try {
      await loadLinksRemote(user);
    } catch (_) {
      // A committed mutation is successful even if the follow-up read is offline.
    }
  }

  void clearSession() {
    _sessionEpoch++;
    _snapshots.clear();
    _requests.clear();
    _appliedRequests.clear();
  }

  GuardianLinkSummary? cachedSummary(String userId) {
    final links = _snapshots[userId];
    if (links == null) return null;
    return GuardianLinkSummary(
      confirmedLinks: links
          .where((l) => l.guardianId == userId && l.isConfirmed)
          .toList(),
      pendingLinks: links
          .where((l) => l.guardianId == userId && l.isPending)
          .toList(),
    );
  }

  Future<GuardianLinkSummary> loadCachedSummaryForGuardian(
    String userId,
  ) async {
    if (_userId != userId) {
      return const GuardianLinkSummary(confirmedLinks: [], pendingLinks: []);
    }
    if (!_snapshots.containsKey(userId)) {
      final epoch = _sessionEpoch;
      final links = await _loadLinksLocal(userId);
      if (_userId != userId || epoch != _sessionEpoch) {
        return const GuardianLinkSummary(confirmedLinks: [], pendingLinks: []);
      }
      _snapshots.putIfAbsent(userId, () => links);
    }
    return cachedSummary(userId)!;
  }

  Future<List<StudentSearchResult>> searchStudents(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) return const [];

    if (_userId == null) {
      throw GuardianLinkRepositoryException('Nicht angemeldet.');
    }

    try {
      await _ensureCallerIsGuardian();
      return await _searchViaRpc(trimmed);
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        debugPrint(
          'search_students_for_guardian RPC fehlgeschlagen: ${e.code}',
        );
      }
      throw GuardianLinkRepositoryException(_mapSearchError(e));
    } on GuardianLinkRepositoryException {
      rethrow;
    } catch (e) {
      throw GuardianLinkRepositoryException(
        'Schüler-Suche fehlgeschlagen. Bitte erneut versuchen.',
      );
    }
  }

  Future<List<StudentSearchResult>> _searchViaRpc(String query) async {
    final rows = await _supabase.rpc(
      'search_students_for_guardian',
      params: {'p_query': query},
    );
    return _parseStudentRows(rows);
  }

  List<StudentSearchResult> _parseStudentRows(Object? rows) {
    if (rows == null) return const [];

    final rawList = rows is List
        ? rows
        : rows is Map
        ? [rows]
        : const [];

    final results = <StudentSearchResult>[];
    for (final row in rawList) {
      if (row is! Map) continue;
      final parsed = StudentSearchResult.fromJson(
        Map<String, dynamic>.from(row),
      );
      if (parsed.id.isNotEmpty) results.add(parsed);
    }
    return results;
  }

  Future<void> _ensureCallerIsGuardian() async {
    final userId = _userId;
    if (userId == null) {
      throw GuardianLinkRepositoryException('Nicht angemeldet.');
    }

    final row = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();
    final role = row?['role']?.toString().trim();
    if (role == LoginFlowRoleIds.guardian || role == ProfileRoleIds.admin) {
      return;
    }

    throw GuardianLinkRepositoryException(
      'Nur Elternteile können Kinder anfragen.',
    );
  }

  String _mapSearchError(PostgrestException e) {
    final message = e.message.toLowerCase();
    if (message.contains('infinite recursion') ||
        message.contains('recursion')) {
      return 'Profil-Zugriff fehlgeschlagen. Bitte App neu starten und erneut versuchen.';
    }
    if (message.contains('elternteil') ||
        message.contains('forbidden') ||
        e.code == '42501') {
      return 'Nur Elternteile können nach Schülern suchen. Bitte Rolle prüfen.';
    }
    if (message.contains('not authenticated')) {
      return 'Bitte melde dich erneut an.';
    }
    return 'Schüler-Suche fehlgeschlagen: ${e.message}';
  }

  Future<GuardianLinkRequestResult> requestLink(String childId) async {
    final userId = _userId;
    if (userId == null) {
      throw GuardianLinkRepositoryException('Nicht angemeldet.');
    }

    final result = await requestLinks([childId]);
    return GuardianLinkRequestResult(
      link: result.createdLinks.single,
      notifyResult:
          result.notifyResults[result.createdLinks.single.id] ??
          const NotifyLinkResult(pushAccepted: false),
    );
  }

  Future<RequestLinksResult> requestLinks(List<String> childIds) async {
    if (childIds.isEmpty) {
      throw GuardianLinkRepositoryException(
        'Bitte mindestens ein Kind auswählen.',
      );
    }

    final userId = _userId;
    if (userId == null) {
      throw GuardianLinkRepositoryException('Nicht angemeldet.');
    }

    final epoch = _sessionEpoch;
    try {
      final rows = await _supabase.rpc(
        'request_guardian_links',
        params: {'p_child_ids': childIds},
      );

      final createdLinks = <GuardianChildLink>[];
      final skippedChildIds = <String>[];
      final seenChildIds = <String>{};

      if (rows is! List) {
        throw GuardianLinkRepositoryException(
          'Ungültige Serverantwort. Bitte Status aktualisieren.',
        );
      }
      final rawList = rows;
      for (final row in rawList) {
        if (row is! Map) continue;
        final data = Map<String, dynamic>.from(row);
        final link = GuardianChildLink.fromRow(data);
        seenChildIds.add(link.childId);
        final wasInserted = data['was_inserted'] == true;
        if (wasInserted) {
          createdLinks.add(link);
        } else {
          skippedChildIds.add(link.childId);
        }
      }

      for (final childId in childIds) {
        if (!seenChildIds.contains(childId)) {
          skippedChildIds.add(childId);
        }
      }

      if (_userId != userId || epoch != _sessionEpoch) {
        throw GuardianLinkRepositoryException('Sitzung geändert.');
      }
      final existing = _snapshots[userId] ?? const <GuardianChildLink>[];
      await _accept(userId, [
        for (final link in existing)
          if (!createdLinks.any((c) => c.id == link.id)) link,
        ...createdLinks,
      ]);
      await _refreshAfterCommit(userId);
      var anyPushFailed = false;
      final byLink = <String, NotifyLinkResult>{};
      if (createdLinks.isNotEmpty) {
        final notifyResults = await Future.wait(
          createdLinks.map((link) => _notifyLinkAction(link.id, 'request')),
        );
        anyPushFailed = notifyResults.any((result) => !result.pushAccepted);
        for (var i = 0; i < createdLinks.length; i++) {
          byLink[createdLinks[i].id] = notifyResults[i];
        }
      }

      if (createdLinks.isEmpty && skippedChildIds.length == childIds.length) {
        throw GuardianLinkRepositoryException(
          'Anfragen an alle ausgewählten Kinder wurden bereits gesendet.',
        );
      }

      return RequestLinksResult(
        createdLinks: createdLinks,
        skippedChildIds: skippedChildIds.toList(growable: false),
        anyPushFailed: anyPushFailed,
        notifyResults: byLink,
      );
    } on PostgrestException catch (e) {
      throw GuardianLinkRepositoryException(e.message);
    } on GuardianLinkRepositoryException {
      rethrow;
    } catch (e) {
      throw GuardianLinkRepositoryException(
        'Verknüpfungsanfrage fehlgeschlagen. Bitte erneut versuchen.',
      );
    }
  }

  Future<void> respondToLink({
    required String linkId,
    required bool accept,
    int? expectedRevision,
    GuardianChildSharePermissions sharePermissions =
        GuardianChildSharePermissions.minimal,
  }) async {
    final userId = _userId;
    if (userId == null) {
      throw GuardianLinkRepositoryException('Nicht angemeldet.');
    }

    await _changeLink(
      linkId,
      accept ? 'confirm' : 'reject',
      sharePermissions,
      expectedRevision: expectedRevision,
    );
  }

  Future<void> updateSharePermissions({
    required String linkId,
    required GuardianChildSharePermissions sharePermissions,
    int? expectedRevision,
  }) => _changeLink(
    linkId,
    'permissions',
    sharePermissions,
    expectedRevision: expectedRevision,
  );

  Future<void> revokeLink(String linkId) =>
      _changeLink(linkId, 'revoke', GuardianChildSharePermissions.minimal);

  Future<void> _changeLink(
    String id,
    String action,
    GuardianChildSharePermissions permissions, {
    int? expectedRevision,
  }) async {
    final user = _userId;
    final epoch = _sessionEpoch;
    if (user == null) {
      throw GuardianLinkRepositoryException('Nicht angemeldet.');
    }
    try {
      final link = await fetchLinkById(id);
      if (_userId != user || epoch != _sessionEpoch || link == null) {
        throw GuardianLinkRepositoryException('Anfrage nicht mehr verfügbar.');
      }
      final response = await _supabase
          .rpc(
            'change_guardian_link',
            params: {
              'p_link_id': id,
              'p_action': action,
              'p_revision': expectedRevision ?? link.revision,
              'p_permissions': permissions.toJson(),
            },
          )
          .timeout(const Duration(seconds: 15));
      if (_userId != user || epoch != _sessionEpoch) return;
      final changed = GuardianChildLink.fromRow(
        Map<String, dynamic>.from(response as Map),
      );
      final current = _snapshots[user] ?? const <GuardianChildLink>[];
      await _accept(user, [
        for (final existing in current)
          if (existing.id != changed.id)
            existing
          else
            mergeGuardianChildLinks(existing, changed),
        if (!current.any((l) => l.id == changed.id)) changed,
      ]);
      unawaited(_notifyLinkAction(id, action));
      await _refreshAfterCommit(user);
    } on GuardianLinkRepositoryException {
      rethrow;
    } on PostgrestException catch (e) {
      throw GuardianLinkRepositoryException(e.message);
    } catch (_) {
      throw GuardianLinkRepositoryException(
        'Änderung konnte nicht bestätigt werden. Bitte Verbindung prüfen und erneut versuchen.',
      );
    }
  }

  Future<void> sendReminder(String linkId) async {
    final user = _userId;
    final epoch = _sessionEpoch;
    if (user == null) {
      throw GuardianLinkRepositoryException('Nicht angemeldet.');
    }
    try {
      await _supabase
          .rpc('request_guardian_reminder', params: {'p_link_id': linkId})
          .timeout(const Duration(seconds: 15));
      if (_userId != user || epoch != _sessionEpoch) return;
      final result = await _notifyLinkAction(linkId, 'reminder');
      await _refreshAfterCommit(user);
      if (!result.pushAccepted) {
        throw GuardianLinkRepositoryException(
          'Erinnerung vorgemerkt. Der Push-Dienst hat noch keine Nachricht angenommen.',
        );
      }
    } on GuardianLinkRepositoryException {
      rethrow;
    } on PostgrestException catch (e) {
      throw GuardianLinkRepositoryException(e.message);
    } catch (_) {
      throw GuardianLinkRepositoryException(
        'Erinnerung konnte nicht bestätigt werden. Bitte Verbindung prüfen und den Status aktualisieren.',
      );
    }
  }

  Future<void> setActiveChild(String childId) async {
    final userId = _userId;
    if (userId == null) {
      throw GuardianLinkRepositoryException('Nicht angemeldet.');
    }

    try {
      await _supabase
          .from('profiles')
          .update({'active_child_id': childId})
          .eq('id', userId);
    } catch (_) {
      throw GuardianLinkRepositoryException(
        'Aktives Kind konnte nicht gespeichert werden.',
      );
    }
  }

  Stream<List<GuardianChildLink>> watchLinksForUser(String userId) {
    late StreamController<List<GuardianChildLink>> controller;
    StreamSubscription? changes;
    StreamSubscription? local;
    Timer? poll;
    bool busy = false;
    bool closed = false;
    Future<void> refresh() async {
      if (closed || busy || _userId != userId) return;
      busy = true;
      try {
        await loadLinksRemote(userId);
      } catch (error, stack) {
        if (!closed) controller.addError(error, stack);
      } finally {
        busy = false;
      }
    }

    controller = StreamController<List<GuardianChildLink>>(
      onListen: () async {
        changes = _changes.stream.where((id) => id == userId).listen((_) {
          if (!closed && _userId == userId) {
            controller.add(_snapshots[userId] ?? []);
          }
        });
        if (_snapshots.containsKey(userId)) {
          controller.add(_snapshots[userId]!);
        } else {
          try {
            final cache = await _loadLinksLocal(userId);
            if (!closed &&
                _userId == userId &&
                !_snapshots.containsKey(userId)) {
              controller.add(cache);
            }
          } catch (_) {
            /* The authoritative refresh reports failures below. */
          }
        }
        if (closed) return;
        local = _db
            ?.watch(
              'SELECT * FROM $kGuardianChildLinksTable WHERE guardian_id = ? OR child_id = ?',
              parameters: [userId, userId],
            )
            .listen((rows) {
              if (closed || _userId != userId) return;
              final localLinks = rows
                  .map(
                    (r) =>
                        GuardianChildLink.fromRow(Map<String, dynamic>.from(r)),
                  )
                  .toList();
              final current = _snapshots[userId];
              if (current != null) {
                final byId = {for (final link in localLinks) link.id: link};
                final merged = [
                  for (final link in current)
                    if (byId[link.id] != null &&
                        byId[link.id]!.revision > link.revision)
                      byId[link.id]!
                    else
                      link,
                ];
                if (merged.asMap().entries.any(
                  (e) => !identical(e.value, current[e.key]),
                )) {
                  unawaited(_accept(userId, merged));
                }
              }
              unawaited(refresh());
            }, onError: (Object _) {});
        poll = Timer.periodic(
          const Duration(seconds: 30),
          (_) => unawaited(refresh()),
        );
        await refresh();
      },
      onCancel: () async {
        closed = true;
        poll?.cancel();
        await changes?.cancel();
        await local?.cancel();
      },
    );
    return controller.stream;
  }

  Stream<List<GuardianChildLink>> watchPendingForChild(String childId) =>
      watchLinksForUser(
        childId,
      ).map((links) => pendingLinksForChild(links, childId));

  Future<List<GuardianChildLink>> loadPendingLinksForChild(
    String childId,
  ) async => pendingLinksForChild(await loadLinksRemote(childId), childId);

  /// Filtert aus einer Link-Liste die ausstehenden Anfragen für ein Kind.
  @visibleForTesting
  static List<GuardianChildLink> pendingLinksForChild(
    List<GuardianChildLink> links,
    String childId,
  ) {
    return links
        .where((link) => link.childId == childId && link.isPending)
        .toList(growable: false);
  }

  Future<List<GuardianChildLink>> loadLinksRemote(String userId) async {
    if (_userId != userId) {
      throw GuardianLinkRepositoryException('Sitzung geändert.');
    }
    final epoch = _sessionEpoch;
    final request = (_requests[userId] ?? 0) + 1;
    _requests[userId] = request;
    final rows = await _supabase
        .rpc('guardian_link_snapshot')
        .timeout(const Duration(seconds: 12));
    if (_userId != userId || epoch != _sessionEpoch) {
      throw GuardianLinkRepositoryException('Sitzung geändert.');
    }
    if (rows is! List) {
      throw GuardianLinkRepositoryException('Ungültige Serverantwort.');
    }
    final links = rows
        .map(
          (row) =>
              GuardianChildLink.fromRow(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
    if ((_appliedRequests[userId] ?? 0) > request) {
      return _snapshots[userId] ?? links;
    }
    _appliedRequests[userId] = request;
    final merged = mergeGuardianLinkCollections(
      _snapshots[userId] ?? const [],
      links,
    );
    await _accept(userId, merged);
    return merged;
  }

  Future<GuardianLinkSummary> loadSummaryForGuardian(String guardianId) async {
    final own = (await loadLinksRemote(
      guardianId,
    )).where((link) => link.guardianId == guardianId);
    return GuardianLinkSummary(
      confirmedLinks: own.where((l) => l.isConfirmed).toList(),
      pendingLinks: own.where((l) => l.isPending).toList(),
    );
  }

  Future<GuardianChildLink?> fetchLinkById(String linkId) async {
    final user = _userId;
    if (user == null) return null;
    final links = await loadLinksRemote(user);
    for (final link in links) {
      if (link.id == linkId) return link;
    }
    return null;
  }

  Future<NotifyLinkResult> _notifyLinkAction(
    String linkId,
    String action,
  ) async {
    try {
      final response = await _supabase.functions.invoke(
        'notify-guardian-link',
        body: {'link_id': linkId, 'action': action},
      );

      final data = response.data;
      if (data is Map) {
        final sent = _parseInt(data['accepted']);
        final failed = _parseInt(data['failed']);
        return NotifyLinkResult(
          pushAccepted: sent > 0,
          sent: sent,
          failed: failed,
        );
      }

      return const NotifyLinkResult(pushAccepted: false);
    } catch (_) {
      return const NotifyLinkResult(pushAccepted: false);
    }
  }

  int _parseInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<List<GuardianChildLink>> _loadLinksLocal(String userId) async {
    final persisted = await _readPersisted(userId);
    if (persisted != null) return persisted;
    if (_db == null) return const [];
    final rows = await _db.getAll(
      'SELECT * FROM $kGuardianChildLinksTable WHERE guardian_id = ? OR child_id = ?',
      [userId, userId],
    );
    return rows
        .map((row) => GuardianChildLink.fromRow(Map<String, dynamic>.from(row)))
        .toList();
  }
}

class GuardianLinkSummary {
  const GuardianLinkSummary({
    required this.confirmedLinks,
    required this.pendingLinks,
  });

  final List<GuardianChildLink> confirmedLinks;
  final List<GuardianChildLink> pendingLinks;

  bool get hasConfirmedLink => confirmedLinks.isNotEmpty;
  bool get hasPendingLink => pendingLinks.isNotEmpty;
  bool get hasAnyLink => confirmedLinks.isNotEmpty || pendingLinks.isNotEmpty;
}
