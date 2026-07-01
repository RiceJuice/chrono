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

const _sharpPitchClasses = {1, 3, 6, 8, 10};

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

  /// Nur der natürliche Tonbuchstabe ohne Vorzeichen, z. B. „a“.
  String get noteLetter => naturalNoteLetter;

  /// Natürlicher Buchstabe der gestimmten Note (ohne ♯/♭).
  String get naturalNoteLetter {
    final pitchClass = _pitchClassNames.indexOf(noteName);
    if (pitchClass < 0) {
      return noteName.substring(0, 1).toLowerCase();
    }
    return _naturalNoteLetterForPitchClass(pitchClass);
  }

  /// Vorzeichen der gestimmten Note (♯), nicht die Abweichung vom Zielton.
  String? get noteAccidental {
    final pitchClass = _pitchClassNames.indexOf(noteName);
    if (pitchClass < 0 || !_sharpPitchClasses.contains(pitchClass)) {
      return null;
    }
    return '♯';
  }

  bool get hasTuningSymbol => tuningSymbol != null;
}

String _naturalNoteLetterForPitchClass(int pitchClass) {
  return switch (pitchClass) {
    0 => 'c',
    1 => 'c',
    2 => 'd',
    3 => 'd',
    4 => 'e',
    5 => 'f',
    6 => 'f',
    7 => 'g',
    8 => 'g',
    9 => 'a',
    10 => 'a',
    11 => 'b',
    _ => 'c',
  };
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

  // Bei gerundeter Anzeige nur die gestimmte Note zeigen – keine zusätzlichen
  // Vorzeichen, die sonst zu doppelten ♯/♭ (z. B. „a♯♯“) führen würden.
  String? tuningSymbol;
  if (!displayTemperedFrequency) {
    if (cents > symbolThresholdCents) {
      tuningSymbol = '♯';
    } else if (cents < -symbolThresholdCents) {
      tuningSymbol = '♭';
    }
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
