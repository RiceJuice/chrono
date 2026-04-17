import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'profile_gate_notifier.dart';

/// Die App-weit genutzte Instanz des [ProfileGateNotifier]. Wird in `main.dart`
/// über [ProviderScope.overrides] mit der vom Router geteilten Instanz
/// überschrieben, damit Pages nach Profil-Änderungen `refresh()` aufrufen können
/// und der Router sofort reagiert.
final profileGateProvider = Provider<ProfileGateNotifier>((ref) {
  throw StateError(
    'profileGateProvider is not initialized. Override it in ProviderScope '
    'with the ProfileGateNotifier instance used by AppRouter.',
  );
});
