import 'package:chronoapp/features/login/domain/models/guardian_child_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StudentSearchResult.fromJson', () {
    test('parst RPC-Zeilen mit student_id', () {
      final result = StudentSearchResult.fromJson({
        'student_id': '433fe89f-7034-4e9e-999f-027b89b6a19f',
        'first_name': 'Antonius',
        'last_name': 'Weber',
        'class_name': '10a',
        'profile_name': 'Antonius Weber',
      });

      expect(result.id, '433fe89f-7034-4e9e-999f-027b89b6a19f');
      expect(result.displayName, 'Antonius Weber');
    });

    test('parst REST-Zeilen mit id', () {
      final result = StudentSearchResult.fromJson({
        'id': 'bfe33df6-9171-47d2-aadd-2b28fd378fe3',
        'first_name': 'Sebastian',
        'last_name': 'Bleitzhofer',
        'class_name': '10a',
      });

      expect(result.id, 'bfe33df6-9171-47d2-aadd-2b28fd378fe3');
      expect(result.displayName, 'Sebastian Bleitzhofer');
    });
  });
}
