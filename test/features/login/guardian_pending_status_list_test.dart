import 'package:chronoapp/features/login/presentation/pages/guardian_pending/guardian_pending_status_list.dart';
import 'package:chronoapp/features/login/domain/models/guardian_child_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pendingLinkStatus', () {
    test('mappt Link-Status auf Anzeige-Status', () {
      const pending = GuardianChildLink(
        id: '1',
        guardianId: 'g',
        childId: 'c',
        status: GuardianLinkStatus.pending,
      );
      const confirmed = GuardianChildLink(
        id: '2',
        guardianId: 'g',
        childId: 'c',
        status: GuardianLinkStatus.confirmed,
      );
      const rejected = GuardianChildLink(
        id: '3',
        guardianId: 'g',
        childId: 'c',
        status: GuardianLinkStatus.rejected,
      );

      expect(pendingLinkStatus(pending), GuardianPendingLinkStatus.waiting);
      expect(pendingLinkStatus(confirmed), GuardianPendingLinkStatus.confirmed);
      expect(pendingLinkStatus(rejected), GuardianPendingLinkStatus.rejected);
    });
  });
}
