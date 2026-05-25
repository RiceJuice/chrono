import 'package:chronoapp/core/database/postgres_enum_array_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PostgresEnumArrayCodec', () {
    test('toSupabaseArray wraps scalar choir label', () {
      expect(
        PostgresEnumArrayCodec.toSupabaseArray('Giehl'),
        ['Giehl'],
      );
    });

    test('toSupabaseArray parses postgres array literal', () {
      expect(
        PostgresEnumArrayCodec.toSupabaseArray('{Giehl}'),
        ['Giehl'],
      );
    });

    test('decodeFirstToken reads json-encoded local value', () {
      expect(
        PostgresEnumArrayCodec.decodeFirstToken('["Giehl"]'),
        'Giehl',
      );
    });

    test('encodeLocalSingle produces json array text', () {
      expect(
        PostgresEnumArrayCodec.encodeLocalSingle('Giehl'),
        '["Giehl"]',
      );
    });
  });
}
