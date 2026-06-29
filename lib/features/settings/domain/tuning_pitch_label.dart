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

/// MIDI-Float (69 = A4) für eine Frequenz in Hz.
double tuningMidiFloatForFrequency(double frequencyHz) {
  return tuningReferenceMidi +
      12 * (math.log(frequencyHz / tuningReferenceFrequencyHz) / math.ln2);
}

/// Temperierte Referenzfrequenz für eine MIDI-Note.
double tuningTemperedFrequencyHzForMidi(int midiNote) {
  return tuningReferenceFrequencyHz *
      math.pow(2, (midiNote - tuningReferenceMidi) / 12);
}

/// Wandelt eine Frequenz in Hz + Notenname mit optionalem ♯/♭ (zu hoch/tief) um.
///
/// [symbolThresholdCents]: Abweichung in Cent, ab der ♯/♭ angezeigt wird.
/// [displayTemperedFrequency]: Zeigt die nächste gestimmte Frequenz statt der
/// gemessenen Hz – stabiler bei Vibrato.
TuningPitchLabel tuningPitchLabelForFrequency(
  double frequencyHz, {
  int? lockedMidiNote,
  double symbolThresholdCents = 35,
  bool displayTemperedFrequency = false,
}) {
  final midiFloat = tuningMidiFloatForFrequency(frequencyHz);
  final midiNearest = lockedMidiNote ?? midiFloat.round();
  final pitchClass = ((midiNearest % 12) + 12) % 12;
  final octave = (midiNearest ~/ 12) - 1;
  final referenceHz = tuningTemperedFrequencyHzForMidi(midiNearest);
  final cents = 1200 * (math.log(frequencyHz / referenceHz) / math.ln2);

  String? tuningSymbol;
  if (cents > symbolThresholdCents) {
    tuningSymbol = '♯';
  } else if (cents < -symbolThresholdCents) {
    tuningSymbol = '♭';
  }

  final displayHz = displayTemperedFrequency
      ? referenceHz.round()
      : frequencyHz.round();

  return TuningPitchLabel(
    frequencyHz: displayHz,
    noteName: _pitchClassNames[pitchClass],
    octave: octave,
    tuningSymbol: tuningSymbol,
  );
}
