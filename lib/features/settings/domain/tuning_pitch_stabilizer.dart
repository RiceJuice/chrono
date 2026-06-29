import 'package:chronoapp/features/settings/domain/tuning_pitch_label.dart';

/// Hält die angezeigte Note stabil, auch wenn Vibrato die Frequenz schwankt.
class TuningPitchStabilizer {
  TuningPitchStabilizer({
    this.noteSwitchMarginCents = 40,
    this.symbolThresholdCents = 35,
  });

  /// Zusätzlicher Abstand zur Notengrenze, bevor die Anzeige umspringt.
  final double noteSwitchMarginCents;

  /// Abweichung in Cent, ab der ♯/♭ erscheint.
  final double symbolThresholdCents;

  int? _lockedMidi;

  void reset() {
    _lockedMidi = null;
  }

  TuningPitchLabel? labelForFrequency(double? frequencyHz) {
    if (frequencyHz == null) {
      reset();
      return null;
    }

    final midiFloat = tuningMidiFloatForFrequency(frequencyHz);
    _lockedMidi = _resolveLockedMidi(midiFloat, _lockedMidi);

    return tuningPitchLabelForFrequency(
      frequencyHz,
      lockedMidiNote: _lockedMidi,
      symbolThresholdCents: symbolThresholdCents,
      displayTemperedFrequency: true,
    );
  }

  int _resolveLockedMidi(double midiFloat, int? current) {
    if (current == null) {
      return midiFloat.round();
    }

    final nearest = midiFloat.round();
    if (nearest == current) {
      return current;
    }

    final marginSemitones = noteSwitchMarginCents / 100;
    if (nearest > current) {
      final switchThreshold = current + 0.5 + marginSemitones;
      return midiFloat >= switchThreshold ? nearest : current;
    }

    final switchThreshold = current - 0.5 - marginSemitones;
    return midiFloat <= switchThreshold ? nearest : current;
  }
}
