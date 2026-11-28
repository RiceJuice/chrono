import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chronoapp/features/login/data/guardian_link_repository.dart';

const testGuardianUser = '00000000-0000-0000-0000-000000000001';
Map<String, dynamic> guardianTestSession(String id) => {
  'access_token':
      '${base64Url.encode(utf8.encode('{"alg":"HS256"}'))}.${base64Url.encode(utf8.encode(jsonEncode({'sub': id, 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600})))}.signature',
  'refresh_token': 'test-refresh',
  'token_type': 'bearer',
  'expires_in': 3600,
  'user': {
    'id': id,
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': 'test@example.invalid',
    'app_metadata': {},
    'user_metadata': {},
    'created_at': '2026-01-01T00:00:00Z',
  },
};
http.Response jsonResponse(String body, int status) => http.Response(
  body,
  status,
  headers: {'content-type': 'application/json'},
  request: http.Request('POST', Uri.parse('https://test.invalid')),
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'server empty and offline failure are distinct; removed push never falls back',
    () async {
      Object rows = [
        {
          'id': 'link',
          'guardian_id': 'parent',
          'child_id': testGuardianUser,
          'status': 'pending',
          'revision': 1,
          'guardian_first_name': 'Alex',
        },
      ];
      var fail = false;
      var reads = 0;
      final client = SupabaseClient(
        'https://test.invalid',
        'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/token')) {
            return jsonResponse(
              jsonEncode(guardianTestSession(testGuardianUser)),
              200,
            );
          }
          if (request.url.path.endsWith('/guardian_link_snapshot')) {
            reads++;
            return jsonResponse(
              fail ? '{"message":"offline"}' : jsonEncode(rows),
              fail ? 503 : 200,
            );
          }
          return jsonResponse('{}', 200);
        }),
      );
      addTearDown(client.dispose);
      await client.auth.signInWithPassword(
        email: 'test@example.invalid',
        password: 'synthetic',
      );
      final repo = GuardianLinkRepository(null, supabase: client);
      expect(
        (await repo.loadPendingLinksForChild(
          testGuardianUser,
        )).single.guardianDisplayName,
        'Alex',
      );
      rows = [];
      expect(await repo.fetchLinkById('link'), isNull);
      fail = true;
      await expectLater(
        repo.loadPendingLinksForChild(testGuardianUser),
        throwsA(isA<PostgrestException>()),
      );
      expect(reads, 3);
      final restarted = GuardianLinkRepository(null, supabase: client);
      expect(
        await restarted.watchLinksForUser(testGuardianUser).first,
        isEmpty,
      );
    },
  );
  test(
    'committed revoke survives failed refresh and repository restart',
    () async {
      var committed = false;
      final row = <String, dynamic>{
        'id': 'link',
        'guardian_id': testGuardianUser,
        'child_id': 'child',
        'status': 'confirmed',
        'revision': 1,
        'child_share_permissions': {'school': true},
      };
      final client = SupabaseClient(
        'https://test.invalid',
        'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/token')) {
            return jsonResponse(
              jsonEncode(guardianTestSession(testGuardianUser)),
              200,
            );
          }
          if (request.url.path.endsWith('/change_guardian_link')) {
            committed = true;
            return jsonResponse(
              jsonEncode({
                ...row,
                'status': 'revoked',
                'revision': 2,
                'child_share_permissions': {'school': false},
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/guardian_link_snapshot')) {
            return committed
                ? jsonResponse('{"message":"offline"}', 503)
                : jsonResponse(jsonEncode([row]), 200);
          }
          return jsonResponse('{"accepted":false}', 200);
        }),
      );
      addTearDown(client.dispose);
      await client.auth.signInWithPassword(
        email: 'test@example.invalid',
        password: 'synthetic',
      );
      final repo = GuardianLinkRepository(null, supabase: client);
      await repo.revokeLink('link');
      expect(committed, true);
      expect(repo.cachedSummary(testGuardianUser)!.hasConfirmedLink, false);
      final restarted = GuardianLinkRepository(null, supabase: client);
      final restored = await restarted
          .watchLinksForUser(testGuardianUser)
          .first;
      expect(restored.single.status, 'revoked');
      expect(restored.single.revision, 2);
      expect(restored.single.sharePermissions.sharesAnything, false);
    },
  );
  test(
    'reminder transport failures remain actionable repository errors',
    () async {
      final client = SupabaseClient(
        'https://test.invalid',
        'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/token')) {
            return jsonResponse(
              jsonEncode(guardianTestSession(testGuardianUser)),
              200,
            );
          }
          throw http.ClientException('offline');
        }),
      );
      addTearDown(client.dispose);
      await client.auth.signInWithPassword(
        email: 'test@example.invalid',
        password: 'synthetic',
      );
      final repo = GuardianLinkRepository(null, supabase: client);
      await expectLater(
        repo.sendReminder('link'),
        throwsA(isA<GuardianLinkRepositoryException>()),
      );
    },
  );
  test('late server response cannot restore older cached consent', () async {
    final responses = <Completer<http.Response>>[];
    final client = SupabaseClient(
      'https://test.invalid',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/token')) {
          return jsonResponse(
            jsonEncode(guardianTestSession(testGuardianUser)),
            200,
          );
        }
        final c = Completer<http.Response>();
        responses.add(c);
        return c.future;
      }),
    );
    addTearDown(client.dispose);
    await client.auth.signInWithPassword(
      email: 'test@example.invalid',
      password: 'synthetic',
    );
    final repo = GuardianLinkRepository(null, supabase: client);
    final first = repo.loadLinksRemote(testGuardianUser);
    await Future<void>.delayed(Duration.zero);
    final second = repo.loadLinksRemote(testGuardianUser);
    await Future<void>.delayed(Duration.zero);
    responses[1].complete(jsonResponse('[]', 200));
    await second;
    responses[0].complete(
      jsonResponse(
        jsonEncode([
          {
            'id': 'link',
            'guardian_id': testGuardianUser,
            'child_id': 'child',
            'status': 'confirmed',
            'revision': 1,
          },
        ]),
        200,
      ),
    );
    expect(await first, isEmpty);
    expect(repo.cachedSummary(testGuardianUser)!.hasConfirmedLink, false);
  });
}
