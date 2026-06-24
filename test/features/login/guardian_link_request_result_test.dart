import 'package:chronoapp/features/login/data/guardian_link_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RequestLinksResult', () {
    test('kennt erstellte Links und Push-Fehler', () {
      const result = RequestLinksResult(
        createdLinks: [],
        skippedChildIds: ['child-a'],
        anyPushFailed: true,
      );

      expect(result.hasCreatedLinks, isFalse);
      expect(result.anyPushFailed, isTrue);
      expect(result.skippedChildIds, ['child-a']);
    });
  });

  group('NotifyLinkResult', () {
    test('markiert erfolgreiche Zustellung ab sent > 0', () {
      const delivered = NotifyLinkResult(pushDelivered: true, sent: 2, failed: 0);
      const notDelivered =
          NotifyLinkResult(pushDelivered: false, sent: 0, failed: 1);

      expect(delivered.pushDelivered, isTrue);
      expect(notDelivered.pushDelivered, isFalse);
    });
  });
}
