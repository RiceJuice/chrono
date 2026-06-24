/// Push-Payload für ausstehende Eltern-Verknüpfungsanfragen (Cold-Start-Puffer).
class GuardianLinkPushPayload {
  const GuardianLinkPushPayload({
    required this.linkId,
    this.guardianName,
  });

  final String linkId;
  final String? guardianName;
}

/// Puffert Push-Payloads, bis [GuardianLinkBootstrap] bereit ist.
class GuardianLinkPushQueue {
  GuardianLinkPushQueue();

  final List<GuardianLinkPushPayload> _pending = [];

  void enqueue(GuardianLinkPushPayload payload) {
    if (_pending.any((p) => p.linkId == payload.linkId)) return;
    _pending.add(payload);
  }

  GuardianLinkPushPayload? peek() =>
      _pending.isEmpty ? null : _pending.first;

  void remove(String linkId) {
    _pending.removeWhere((p) => p.linkId == linkId);
  }

  void transferAllTo(GuardianLinkPushQueue target) {
    for (final payload in _pending) {
      target.enqueue(payload);
    }
    _pending.clear();
  }

  bool get isEmpty => _pending.isEmpty;

  int get length => _pending.length;
}
