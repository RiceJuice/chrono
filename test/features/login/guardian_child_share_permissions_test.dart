import 'package:chronoapp/features/login/domain/models/guardian_child_link.dart';
import 'package:chronoapp/features/login/domain/models/guardian_child_share_permissions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GuardianChildSharePermissions.fromJson', () {
    test('liest bool-Werte aus einer Map', () {
      final permissions = GuardianChildSharePermissions.fromJson({
        'school': true,
        'meal': false,
        'choir': true,
        'homework': false,
      });

      expect(permissions.shareSchool, isTrue);
      expect(permissions.shareMeal, isFalse);
      expect(permissions.shareChoir, isTrue);
      expect(permissions.shareHomework, isFalse);
    });

    test('parst JSON-String aus PowerSync (Text-Spalte)', () {
      final permissions = GuardianChildSharePermissions.fromJson(
        '{"school":true,"meal":true,"choir":false,"homework":true}',
      );

      expect(permissions.shareSchool, isTrue);
      expect(permissions.shareMeal, isTrue);
      expect(permissions.shareChoir, isFalse);
      expect(permissions.shareHomework, isTrue);
    });

    test('leerer JSON-String liefert minimal', () {
      expect(
        GuardianChildSharePermissions.fromJson('{}'),
        GuardianChildSharePermissions.minimal,
      );
    });
  });

  group('GuardianChildLink.fromRow', () {
    test('parst child_share_permissions als JSON-String', () {
      final link = GuardianChildLink.fromRow({
        'id': 'link-1',
        'guardian_id': 'guardian-1',
        'child_id': 'child-1',
        'status': 'confirmed',
        'child_share_permissions':
            '{"school":true,"meal":false,"choir":false,"homework":false}',
      });

      expect(link.sharePermissions.shareSchool, isTrue);
      expect(link.sharePermissions.shareMeal, isFalse);
    });
  });
}
