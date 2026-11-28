import 'package:chronoapp/features/login/domain/guardian_link_status.dart';
import 'package:chronoapp/features/login/domain/models/guardian_child_link.dart';
import 'package:chronoapp/features/login/domain/models/guardian_child_share_permissions.dart';
import 'package:flutter_test/flutter_test.dart';

GuardianChildLink link(String status, {bool shared = false}) =>
    GuardianChildLink(
      id: 'link',
      guardianId: 'parent',
      childId: 'child',
      status: status,
      sharePermissions: GuardianChildSharePermissions(shareSchool: shared),
    );
void main() {
  test('remote revocation supersedes cached confirmation', () {
    expect(
      mergeGuardianChildLinks(
        link('confirmed', shared: true),
        link('revoked'),
      ).status,
      'revoked',
    );
  });
  test('explicit remote denial supersedes cached consent', () {
    expect(
      mergeGuardianChildLinks(
        link('confirmed', shared: true),
        link('confirmed'),
      ).sharePermissions.sharesAnything,
      false,
    );
  });
}
