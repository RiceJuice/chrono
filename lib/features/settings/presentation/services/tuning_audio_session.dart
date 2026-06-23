import 'package:audioplayers/audioplayers.dart';

/// Gemeinsame Audio-Session für Mikrofon-Aufnahme und Lautsprecher-Wiedergabe.
abstract final class TuningAudioSession {
  static Future<void> ensureConfigured() {
    return AudioPlayer.global.setAudioContext(
      AudioContextConfig(
        route: AudioContextConfigRoute.speaker,
        respectSilence: false,
      ).build(),
    );
  }
}
