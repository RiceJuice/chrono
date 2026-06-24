import 'dart:async';

import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/profile_role_ids.dart';
import '../../../core/database/powersync_schema.dart';
import '../domain/models/guardian_child_link.dart';
import '../domain/models/login_flow_role_ids.dart';

class GuardianLinkRepositoryException implements Exception {
  GuardianLinkRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NotifyLinkResult {
  const NotifyLinkResult({
    required this.pushDelivered,
    this.sent = 0,
    this.failed = 0,
  });

  final bool pushDelivered;
  final int sent;
  final int failed;
}

class RequestLinksResult {
  const RequestLinksResult({
    required this.createdLinks,
    required this.skippedChildIds,
    required this.anyPushFailed,
  });

  final List<GuardianChildLink> createdLinks;
  final List<String> skippedChildIds;
  final bool anyPushFailed;

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
  GuardianLinkRepository(
    this._db, {
    SupabaseClient? supabase,
  }) : _supabase = supabase ?? Supabase.instance.client;

  final PowerSyncDatabase? _db;
  final SupabaseClient _supabase;

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<List<StudentSearchResult>> searchStudents(
    String query, {
    List<String> classNames = const [],
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];

    if (_userId == null) {
      throw GuardianLinkRepositoryException('Nicht angemeldet.');
    }

    final normalizedClasses = classNames
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList(growable: false);

    try {
      await _ensureCallerIsGuardian();

      final fromRpc = await _searchViaRpc(trimmed, normalizedClasses);
      if (fromRpc.isNotEmpty) return fromRpc;

      final fromList =
          await _searchViaListAndFilter(trimmed, normalizedClasses);
      if (fromList.isNotEmpty) return fromList;

      final fromRest =
          await _searchViaRestAndFilter(trimmed, normalizedClasses);
      if (fromRest.isNotEmpty) return fromRest;

      return const [];
    } on PostgrestException catch (e) {
      throw GuardianLinkRepositoryException(_mapSearchError(e));
    } on GuardianLinkRepositoryException {
      rethrow;
    } catch (e) {
      throw GuardianLinkRepositoryException(
        'Schüler-Suche fehlgeschlagen. Bitte erneut versuchen.',
      );
    }
  }

  Future<List<StudentSearchResult>> _searchViaRpc(
    String query,
    List<String> classNames,
  ) async {
    final params = <String, dynamic>{'p_query': query};
    if (classNames.isNotEmpty) {
      params['p_class_names'] = classNames;
    }
    final rows = await _supabase.rpc(
      'search_students_for_guardian',
      params: params,
    );
    return _parseStudentRows(rows);
  }

  Future<List<StudentSearchResult>> _searchViaListAndFilter(
    String query,
    List<String> classNames,
  ) async {
    final params = classNames.isNotEmpty
        ? <String, dynamic>{'p_class_names': classNames}
        : null;
    final rows = params == null
        ? await _supabase.rpc('list_searchable_students_for_guardian')
        : await _supabase.rpc(
            'list_searchable_students_for_guardian',
            params: params,
          );
    return _filterStudents(_parseStudentRows(rows), query, classNames);
  }

  Future<List<StudentSearchResult>> _searchViaRestAndFilter(
    String query,
    List<String> classNames,
  ) async {
    var builder = _supabase
        .from('profiles')
        .select('id, first_name, last_name, class_name')
        .inFilter('role', [
          LoginFlowRoleIds.student,
          ProfileRoleIds.admin,
        ])
        .not('onboarding_completed_at', 'is', null);
    if (classNames.isNotEmpty) {
      builder = builder.inFilter('class_name', classNames);
    }
    final rows = await builder.limit(200);
    return _filterStudents(_parseStudentRows(rows), query, classNames);
  }

  List<StudentSearchResult> _filterStudents(
    List<StudentSearchResult> students,
    String query,
    List<String> classNames,
  ) {
    final words = query
        .split(RegExp(r'\s+'))
        .map(_foldGerman)
        .where((word) => word.length >= 2)
        .toList(growable: false);
    if (words.isEmpty) return const [];

    final fullQuery = _foldGerman(query);
    final userId = _userId;

    return students
        .where((student) {
          if (student.id == userId) return false;
          return _studentMatchesQuery(student, words, fullQuery);
        })
        .take(20)
        .toList(growable: false);
  }

  bool _studentMatchesQuery(
    StudentSearchResult student,
    List<String> words,
    String fullQuery,
  ) {
    final profileName = _foldGerman(student.displayName);
    final firstName = _foldGerman(student.firstName);
    final lastName = _foldGerman(student.lastName);

    if (fullQuery.length >= 2 && profileName.contains(fullQuery)) {
      return true;
    }

    return words.every(
      (word) =>
          profileName.contains(word) ||
          firstName.contains(word) ||
          lastName.contains(word),
    );
  }

  String _foldGerman(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('ä', 'a')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ß', 'ss')
        .replaceAll(RegExp(r'\s+'), ' ');
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
    if (role == LoginFlowRoleIds.guardian ||
        role == ProfileRoleIds.admin) {
      return;
    }

    final updated = await _supabase
        .from('profiles')
        .update({'role': LoginFlowRoleIds.guardian})
        .eq('id', userId)
        .select('role')
        .maybeSingle();
    final afterRole = updated?['role']?.toString().trim();
    if (afterRole != LoginFlowRoleIds.guardian &&
        afterRole != ProfileRoleIds.admin) {
      throw GuardianLinkRepositoryException(
        'Rolle konnte nicht gespeichert werden. Bitte erneut versuchen.',
      );
    }
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

    try {
      final inserted = await _supabase
          .from('guardian_child_links')
          .insert({
            'guardian_id': userId,
            'child_id': childId,
            'status': GuardianLinkStatus.pending,
          })
          .select('id, guardian_id, child_id, status, created_at')
          .single();

      final link = GuardianChildLink.fromRow(
        Map<String, dynamic>.from(inserted),
      );

      final notifyResult = await _notifyLinkAction(link.id, 'request');

      return GuardianLinkRequestResult(link: link, notifyResult: notifyResult);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw GuardianLinkRepositoryException(
          'Anfrage an dieses Kind wurde bereits gesendet.',
        );
      }
      throw GuardianLinkRepositoryException(
        'Verknüpfungsanfrage fehlgeschlagen. Bitte erneut versuchen.',
      );
    } on GuardianLinkRepositoryException {
      rethrow;
    } catch (e) {
      throw GuardianLinkRepositoryException(
        'Verknüpfungsanfrage fehlgeschlagen. Bitte erneut versuchen.',
      );
    }
  }

  /// Sendet Verknüpfungsanfragen an mehrere Kinder.
  Future<RequestLinksResult> requestLinks(List<String> childIds) async {
    final uniqueIds = childIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (uniqueIds.isEmpty) {
      throw GuardianLinkRepositoryException(
        'Bitte mindestens ein Kind auswählen.',
      );
    }

    final createdLinks = <GuardianChildLink>[];
    final skippedChildIds = <String>[];
    var anyPushFailed = false;

    for (final childId in uniqueIds) {
      try {
        final result = await requestLink(childId);
        createdLinks.add(result.link);
        if (!result.notifyResult.pushDelivered) {
          anyPushFailed = true;
        }
      } on GuardianLinkRepositoryException catch (e) {
        if (e.message.contains('bereits gesendet')) {
          skippedChildIds.add(childId);
          continue;
        }
        rethrow;
      }
    }

    if (createdLinks.isEmpty && skippedChildIds.length == uniqueIds.length) {
      throw GuardianLinkRepositoryException(
        'Anfragen an alle ausgewählten Kinder wurden bereits gesendet.',
      );
    }

    return RequestLinksResult(
      createdLinks: createdLinks,
      skippedChildIds: skippedChildIds,
      anyPushFailed: anyPushFailed,
    );
  }

  Future<void> respondToLink({
    required String linkId,
    required bool accept,
  }) async {
    final userId = _userId;
    if (userId == null) {
      throw GuardianLinkRepositoryException('Nicht angemeldet.');
    }

    final status =
        accept ? GuardianLinkStatus.confirmed : GuardianLinkStatus.rejected;

    try {
      final updated = await _supabase
          .from('guardian_child_links')
          .update({
            'status': status,
            'responded_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', linkId)
          .eq('child_id', userId)
          .eq('status', GuardianLinkStatus.pending)
          .select('id')
          .maybeSingle();

      if (updated == null) {
        throw GuardianLinkRepositoryException(
          'Antwort konnte nicht gespeichert werden.',
        );
      }

      if (accept) {
        unawaited(_notifyLinkAction(linkId, 'confirmed'));
      } else {
        unawaited(_notifyLinkAction(linkId, 'rejected'));
      }
    } on GuardianLinkRepositoryException {
      rethrow;
    } catch (_) {
      throw GuardianLinkRepositoryException(
        'Antwort konnte nicht gespeichert werden.',
      );
    }
  }

  Future<void> sendReminder(String linkId) async {
    final userId = _userId;
    if (userId == null) {
      throw GuardianLinkRepositoryException('Nicht angemeldet.');
    }

    final link = await _fetchLinkRemote(linkId);
    if (link == null || link.guardianId != userId) {
      throw GuardianLinkRepositoryException('Anfrage nicht gefunden.');
    }
    if (!link.isPending) {
      throw GuardianLinkRepositoryException(
        'Erinnerung nur für ausstehende Anfragen möglich.',
      );
    }

    if (link.reminderSentAt != null) {
      final elapsed = DateTime.now().difference(link.reminderSentAt!);
      if (elapsed.inHours < 24) {
        throw GuardianLinkRepositoryException(
          'Erinnerung kann erst nach 24 Stunden erneut gesendet werden.',
        );
      }
    }

    await _notifyLinkAction(linkId, 'reminder');
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
    final db = _db;
    if (db == null) {
      return Stream.fromFuture(_loadLinksRemote(userId));
    }

    final controller = StreamController<List<GuardianChildLink>>.broadcast();
    StreamSubscription<dynamic>? sub;

    Future<void> emit() async {
      if (controller.isClosed) return;
      try {
        final links = await _loadLinksLocal(userId);
        if (!controller.isClosed) controller.add(links);
      } catch (_) {
        if (!controller.isClosed) controller.add(const []);
      }
    }

    controller.onListen = () async {
      await emit();
      sub = db
          .watch(
            '''
            SELECT id FROM $kGuardianChildLinksTable
            WHERE guardian_id = ? OR child_id = ?
            ''',
            parameters: [userId, userId],
          )
          .listen((_) => unawaited(emit()));
    };

    controller.onCancel = () async {
      await sub?.cancel();
      sub = null;
    };

    return controller.stream;
  }

  Stream<List<GuardianChildLink>> watchPendingForChild(String childId) {
    return watchLinksForUser(childId).map(
      (links) => links.where((l) => l.isPending).toList(growable: false),
    );
  }

  Future<GuardianLinkSummary> loadSummaryForGuardian(String guardianId) async {
    final links = await _loadLinksLocal(guardianId);
    return _summaryFromLinks(links, guardianId);
  }

  /// Lädt den Verknüpfungsstatus direkt vom Server (unabhängig von PowerSync).
  Future<GuardianLinkSummary> loadSummaryForGuardianRemote(
    String guardianId,
  ) async {
    final links = await _loadLinksRemote(guardianId);
    return _summaryFromLinks(links, guardianId);
  }

  GuardianLinkSummary _summaryFromLinks(
    List<GuardianChildLink> links,
    String guardianId,
  ) {
    final confirmed =
        links.where((l) => l.isConfirmed && l.guardianId == guardianId);
    final pending =
        links.where((l) => l.isPending && l.guardianId == guardianId);

    return GuardianLinkSummary(
      confirmedLinks: confirmed.toList(growable: false),
      pendingLinks: pending.toList(growable: false),
    );
  }

  /// Prüft serverseitig, ob ein Kind die Verknüpfung bestätigt hat, und setzt
  /// ggf. das aktive Kind. Gibt die bestätigte Verknüpfung zurück.
  Future<GuardianChildLink?> tryApplyConfirmedLink({
    String? linkId,
    String? guardianId,
  }) async {
    final userId = guardianId ?? _userId;
    if (userId == null) return null;

    GuardianChildLink? confirmed;
    if (linkId != null && linkId.isNotEmpty) {
      final link = await _fetchLinkRemote(linkId);
      if (link != null &&
          link.guardianId == userId &&
          link.isConfirmed) {
        confirmed = link;
      }
    }

    confirmed ??= (await loadSummaryForGuardianRemote(userId))
        .confirmedLinks
        .firstOrNull;

    if (confirmed == null) return null;

    await setActiveChild(confirmed.childId);
    return confirmed;
  }

  Future<GuardianChildLink?> fetchLinkById(String linkId) async {
    return await _fetchLinkRemote(linkId) ?? await _fetchLinkLocal(linkId);
  }

  Future<NotifyLinkResult> _notifyLinkAction(String linkId, String action) async {
    try {
      final response = await _supabase.functions.invoke(
        'notify-guardian-link',
        body: {
          'link_id': linkId,
          'action': action,
        },
      );

      final data = response.data;
      if (data is Map) {
        final sent = _parseInt(data['sent']);
        final failed = _parseInt(data['failed']);
        return NotifyLinkResult(
          pushDelivered: sent > 0,
          sent: sent,
          failed: failed,
        );
      }

      return const NotifyLinkResult(pushDelivered: true);
    } catch (_) {
      return const NotifyLinkResult(pushDelivered: false);
    }
  }

  int _parseInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<GuardianChildLink?> _fetchLinkRemote(String linkId) async {
    try {
      final row = await _supabase
          .from('guardian_child_links')
          .select(
            'id, guardian_id, child_id, status, created_at, responded_at, '
            'reminder_sent_at',
          )
          .eq('id', linkId)
          .maybeSingle();
      if (row == null) return null;
      return GuardianChildLink.fromRow(Map<String, dynamic>.from(row));
    } catch (_) {
      return null;
    }
  }

  Future<GuardianChildLink?> _fetchLinkLocal(String linkId) async {
    final db = _db;
    if (db == null) return _fetchLinkRemote(linkId);
    try {
      final rows = await db.getAll(
        '''
        SELECT id, guardian_id, child_id, status, created_at, responded_at,
               reminder_sent_at
        FROM $kGuardianChildLinksTable
        WHERE id = ?
        LIMIT 1
        ''',
        [linkId],
      );
      if (rows.isEmpty) return null;
      return GuardianChildLink.fromRow(Map<String, dynamic>.from(rows.first));
    } catch (_) {
      return null;
    }
  }

  Future<List<GuardianChildLink>> _loadLinksRemote(String userId) async {
    try {
      final rows = await _supabase
          .from('guardian_child_links')
          .select(
            'id, guardian_id, child_id, status, created_at, responded_at, '
            'reminder_sent_at',
          )
          .or('guardian_id.eq.$userId,child_id.eq.$userId')
          .order('created_at', ascending: false);
      return (rows as List)
          .map((row) => GuardianChildLink.fromRow(
                Map<String, dynamic>.from(row as Map),
              ))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<GuardianChildLink>> _loadLinksLocal(String userId) async {
    final db = _db;
    if (db == null) return _loadLinksRemote(userId);
    try {
      final rows = await db.getAll(
        '''
        SELECT
          gcl.id,
          gcl.guardian_id,
          gcl.child_id,
          gcl.status,
          gcl.created_at,
          gcl.responded_at,
          gcl.reminder_sent_at,
          cp.first_name AS child_first_name,
          cp.last_name AS child_last_name,
          cp.class_name AS child_class_name,
          gp.first_name AS guardian_first_name,
          gp.last_name AS guardian_last_name
        FROM $kGuardianChildLinksTable gcl
        LEFT JOIN $kProfilesTable cp ON cp.id = gcl.child_id
        LEFT JOIN $kProfilesTable gp ON gp.id = gcl.guardian_id
        WHERE gcl.guardian_id = ? OR gcl.child_id = ?
        ORDER BY gcl.created_at DESC
        ''',
        [userId, userId],
      );
      return rows
          .map((row) => GuardianChildLink.fromRow(
                Map<String, dynamic>.from(row),
              ))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
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
