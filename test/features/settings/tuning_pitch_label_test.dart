import 'package:chronoapp/features/settings/domain/tuning_pitch_label.dart';
import 'package:chronoapp/features/settings/domain/tuning_pitch_stabilizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tuningPitchLabelForFrequency', () {
    test('shows flat symbol when clearly below reference', () {
      final label = tuningPitchLabelForFrequency(
        432,
        symbolThresholdCents: 12,
      );
      expect(label.frequencyHz, 432);
      expect(label.noteWithOctave, 'A4');
      expect(label.tuningSymbol, '♭');
    });

    test('shows sharp symbol when clearly above reference', () {
      final label = tuningPitchLabelForFrequency(
        448,
        symbolThresholdCents: 12,
      );
      expect(label.noteWithOctave, 'A4');
      expect(label.tuningSymbol, '♯');
    });

    test('no symbol when close to tempered pitch', () {
      final label = tuningPitchLabelForFrequency(440);
      expect(label.noteWithOctave, 'A4');
      expect(label.noteLetter, 'a');
      expect(label.tuningSymbol, isNull);
    });

    test('no symbol within default vibrato tolerance', () {
      final label = tuningPitchLabelForFrequency(432);
      expect(label.noteWithOctave, 'A4');
      expect(label.tuningSymbol, isNull);
    });

    test('displays tempered frequency when requested', () {
      final label = tuningPitchLabelForFrequency(
        438,
        lockedMidiNote: 69,
        displayTemperedFrequency: true,
      );
      expect(label.frequencyHz, 440);
      expect(label.noteWithOctave, 'A4');
    });
  });

  group('TuningPitchStabilizer', () {
    test('locks to nearest note on first sample', () {
      final stabilizer = TuningPitchStabilizer();
      final label = stabilizer.labelForFrequency(440);
      expect(label?.noteWithOctave, 'A4');
      expect(label?.frequencyHz, 440);
    });

    test('stays on note during vibrato-like swings', () {
      final stabilizer = TuningPitchStabilizer();
      stabilizer.labelForFrequency(440);

      for (final frequency in [435.0, 442.0, 438.0, 445.0, 437.0]) {
        final label = stabilizer.labelForFrequency(frequency);
        expect(label?.noteWithOctave, 'A4');
        expect(label?.frequencyHz, 440);
      }
    });

    test('switches only after clear move to next note', () {
      final stabilizer = TuningPitchStabilizer();
      stabilizer.labelForFrequency(440);

      expect(stabilizer.labelForFrequency(446)?.noteWithOctave, 'A4');

      final switched = stabilizer.labelForFrequency(465);
      expect(switched?.noteWithOctave, 'A♯4');
      expect(switched?.frequencyHz, 466);
    });

    test('resets when input becomes null', () {
      final stabilizer = TuningPitchStabilizer();
      stabilizer.labelForFrequency(440);
      expect(stabilizer.labelForFrequency(null), isNull);

      final label = stabilizer.labelForFrequency(494);
      expect(label?.noteWithOctave, 'B4');
    });
  });
}
