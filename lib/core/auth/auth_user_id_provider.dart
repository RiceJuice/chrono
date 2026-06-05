import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Aktuelle Nutzer-ID; der Provider wird bei Login/Logout neu aufgebaut.
final authUserIdProvider = StreamProvider<String?>((ref) async* {
  final client = Supabase.instance.client;
  yield client.auth.currentSession?.user.id;
  yield* client.auth.onAuthStateChange.map((state) => state.session?.user.id);
});
