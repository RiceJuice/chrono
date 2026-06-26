import 'dart:math' as math;

const tuningReferenceFrequencyHz = 440.0;
const tuningReferenceMidi = 69;

const _pitchClassNames = [
  'C',
  'C♯',
  'D',
  'D♯',
  'E',
  'F',
  'F♯',
  'G',
  'G♯',
  'A',
  'A♯',
  'B',
];

/// Ergebnis der Frequenz-zu-Noten-Anzeige inkl. Stimmungsabweichung.
class TuningPitchLabel {
  const TuningPitchLabel({
    required this.frequencyHz,
    required this.noteName,
    required this.octave,
    this.tuningSymbol,
  });

  final int frequencyHz;
  final String noteName;
  final int octave;
  final String? tuningSymbol;

  String get noteWithOctave => '$noteName$octave';

  /// Nur der Tonbuchstabe ohne Oktavzahl, z. B. „a“ statt „A4“.
  String get noteLetter => noteName.toLowerCase();

  bool get hasTuningSymbol => tuningSymbol != null;
}

/// Wandelt eine Frequenz in Hz + Notenname mit optionalem ♯/♭ (zu hoch/tief) um.
TuningPitchLabel tuningPitchLabelForFrequency(double frequencyHz) {
  final midiFloat =
      tuningReferenceMidi +
      12 * (math.log(frequencyHz / tuningReferenceFrequencyHz) / math.ln2);
  final midiNearest = midiFloat.round();
  final pitchClass = ((midiNearest % 12) + 12) % 12;
  final octave = (midiNearest ~/ 12) - 1;
  final referenceHz = tuningReferenceFrequencyHz *
      math.pow(2, (midiNearest - tuningReferenceMidi) / 12);
  final cents = 1200 * (math.log(frequencyHz / referenceHz) / math.ln2);

  String? tuningSymbol;
  if (cents > 12) {
    tuningSymbol = '♯';
  } else if (cents < -12) {
    tuningSymbol = '♭';
  }

  return TuningPitchLabel(
    frequencyHz: frequencyHz.round(),
    noteName: _pitchClassNames[pitchClass],
    octave: octave,
    tuningSymbol: tuningSymbol,
  );
}
