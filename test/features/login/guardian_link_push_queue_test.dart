import 'package:chronoapp/features/login/presentation/services/guardian_link_push_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GuardianLinkPushQueue', () {
    test('puffert Payloads vor Bootstrap-Start', () {
      final deferred = GuardianLinkPushQueue();
      deferred.enqueue(
        const GuardianLinkPushPayload(
          linkId: 'link-1',
          guardianName: 'Maria Muster',
        ),
      );

      expect(deferred.length, 1);
      expect(deferred.peek()?.linkId, 'link-1');
      expect(deferred.peek()?.guardianName, 'Maria Muster');
    });

    test('überträgt Payloads an aktive Instanz ohne Duplikate', () {
      final deferred = GuardianLinkPushQueue();
      final active = GuardianLinkPushQueue();

      deferred.enqueue(const GuardianLinkPushPayload(linkId: 'link-1'));
      deferred.enqueue(const GuardianLinkPushPayload(linkId: 'link-1'));
      deferred.enqueue(const GuardianLinkPushPayload(linkId: 'link-2'));

      deferred.transferAllTo(active);

      expect(deferred.isEmpty, isTrue);
      expect(active.length, 2);
      expect(active.peek()?.linkId, 'link-1');
    });

    test('entfernt verarbeitete Payloads', () {
      final queue = GuardianLinkPushQueue();
      queue.enqueue(const GuardianLinkPushPayload(linkId: 'link-1'));
      queue.enqueue(const GuardianLinkPushPayload(linkId: 'link-2'));

      queue.remove('link-1');

      expect(queue.length, 1);
      expect(queue.peek()?.linkId, 'link-2');
    });

    test('behält Payload bei peek bis zur expliziten Entfernung', () {
      final queue = GuardianLinkPushQueue();
      queue.enqueue(const GuardianLinkPushPayload(linkId: 'link-1'));

      expect(queue.peek()?.linkId, 'link-1');
      expect(queue.length, 1);

      expect(queue.peek()?.linkId, 'link-1');
      expect(queue.length, 1);
    });
  });
}
