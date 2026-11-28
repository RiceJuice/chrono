import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chronoapp/features/login/data/guardian_link_repository.dart';
import 'package:chronoapp/features/login/domain/models/guardian_child_link.dart';
import 'package:chronoapp/features/login/domain/models/profile_gate_data.dart';
import 'package:chronoapp/features/login/presentation/providers/profile_gate_notifier.dart';
import 'package:chronoapp/features/login/presentation/services/guardian_link_bootstrap.dart';
import 'package:chronoapp/features/login/presentation/services/guardian_link_push_queue.dart';
import 'guardian_link_remote_test.dart'
    show guardianTestSession, testGuardianUser, jsonResponse;

class Gate extends ProfileGateNotifier {
  Gate(SupabaseClient client) : super(client: client);
  int refreshes = 0;
  @override
  bool get isReady => true;
  @override
  ProfileGateData get data => const ProfileGateData.signedOut().copyWith(
    hasSession: true,
    role: 'Schüler',
  );
  @override
  Future<void> refresh({bool remote = true}) async {
    refreshes++;
    notifyListeners();
  }
}

class Links extends GuardianLinkRepository {
  Links(SupabaseClient client) : super(null, supabase: client);
  final events = StreamController<List<GuardianChildLink>>.broadcast();
  Completer<List<GuardianChildLink>>? delayed;
  List<GuardianChildLink> rows = [
    const GuardianChildLink(
      id: 'link',
      guardianId: 'parent',
      childId: testGuardianUser,
      status: 'pending',
      guardianFirstName: 'Alex',
    ),
  ];
  int reads = 0;
  @override
  Stream<List<GuardianChildLink>> watchLinksForUser(String id) => events.stream;
  @override
  Future<List<GuardianChildLink>> loadLinksRemote(String id) {
    reads++;
    return delayed?.future ?? Future.value(rows);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseClient client;
  setUp(() async {
    client = SupabaseClient(
      'https://test.invalid',
      'key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient(
        (r) async => jsonResponse(
          r.url.path.endsWith('/token')
              ? jsonEncode(guardianTestSession(testGuardianUser))
              : '{}',
          200,
        ),
      ),
    );
    await client.auth.signInWithPassword(
      email: 'test@example.invalid',
      password: 'synthetic',
    );
  });
  tearDown(() => client.dispose());
  testWidgets(
    'parallel opens serialize; Later survives resume and sync; dispose cancels late work',
    (t) async {
      final gate = Gate(client);
      final links = Links(client);
      final key = GlobalKey<NavigatorState>();
      addTearDown(() {
        gate.dispose();
      });
      addTearDown(() async {
        await links.events.close();
      });
      await t.pumpWidget(
        MaterialApp(
          navigatorKey: key,
          home: const Scaffold(body: Text('App')),
        ),
      );
      final bootstrap = GuardianLinkBootstrap(
        profileGate: gate,
        navigatorKey: key,
        guardianLinkRepository: links,
        supabase: client,
      );
      links.delayed = Completer();
      final first = bootstrap.openPendingRequests();
      final second = bootstrap.openPendingRequests();

      expect(links.reads, 1);
      links.delayed!.complete(links.rows);
      links.delayed = null;
      await second;
      await t.pumpAndSettle();
      expect(find.text('Verknüpfungsanfrage'), findsOneWidget);
      await t.ensureVisible(find.text('Später'));
      await t.tap(find.text('Später'));
      await t.pumpAndSettle();
      await first;
      bootstrap.didChangeAppLifecycleState(AppLifecycleState.resumed);
      links.events.add(links.rows);
      await t.pumpAndSettle();
      expect(links.reads, 2);
      expect(find.text('Verknüpfungsanfrage'), findsNothing);
      links.delayed = Completer();
      final late = bootstrap.openPendingRequests();
      bootstrap.dispose();
      links.delayed!.complete(links.rows);
      await late;
      await t.pumpAndSettle();
      expect(find.text('Verknüpfungsanfrage'), findsNothing);
    },
  );
  testWidgets(
    'invalid queued links cannot block valid recipient and logout closes sheet',
    (t) async {
      final gate = Gate(client);
      final links = Links(client);
      final key = GlobalKey<NavigatorState>();
      addTearDown(() {
        gate.dispose();
      });
      addTearDown(() async {
        await links.events.close();
      });
      await t.pumpWidget(
        MaterialApp(
          navigatorKey: key,
          home: const Scaffold(body: Text('App')),
        ),
      );
      final queue = GuardianLinkPushQueue()
        ..enqueue(const GuardianLinkPushPayload(linkId: 'missing'))
        ..enqueue(const GuardianLinkPushPayload(linkId: 'link'));
      final bootstrap = GuardianLinkBootstrap(
        profileGate: gate,
        navigatorKey: key,
        guardianLinkRepository: links,
        supabase: client,
        pushQueue: queue,
      );
      addTearDown(bootstrap.dispose);
      await t.pumpAndSettle();
      expect(find.text('Verknüpfungsanfrage'), findsOneWidget);
      await t.runAsync(() => client.auth.signOut(scope: SignOutScope.local));
      await t.pumpAndSettle();
      expect(find.text('Verknüpfungsanfrage'), findsNothing);
      expect(queue.isEmpty, true);
    },
  );
}
