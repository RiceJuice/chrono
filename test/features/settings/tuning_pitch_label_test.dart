import 'package:chronoapp/features/settings/domain/tuning_pitch_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tuningPitchLabelForFrequency', () {
    test('shows flat symbol when below reference', () {
      final label = tuningPitchLabelForFrequency(432);
      expect(label.frequencyHz, 432);
      expect(label.noteWithOctave, 'A4');
      expect(label.tuningSymbol, '♭');
    });

    test('shows sharp symbol when above reference', () {
      final label = tuningPitchLabelForFrequency(448);
      expect(label.noteWithOctave, 'A4');
      expect(label.tuningSymbol, '♯');
    });

    test('no symbol when close to tempered pitch', () {
      final label = tuningPitchLabelForFrequency(440);
      expect(label.noteWithOctave, 'A4');
      expect(label.tuningSymbol, isNull);
    });
  });
}
