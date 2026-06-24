import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:chronoapp/features/settings/presentation/services/tuning_audio_session.dart';
import 'package:flutter/foundation.dart';

class TuningReferenceTonePlayer {
  TuningReferenceTonePlayer({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  static const referenceFrequencyHz = 440.0;
  static const assetPath = 'audio/piano_a440.wav';
  static const _fallbackDuration = Duration(seconds: 4);

  final AudioPlayer _player;
  StreamSubscription<void>? _completeSubscription;
  Timer? _fallbackTimer;

  Future<void> play({required VoidCallback onComplete}) async {
    await stop();

    await TuningAudioSession.ensureConfigured();
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setVolume(1);

    var completed = false;
    void completeOnce() {
      if (completed) return;
      completed = true;
      _fallbackTimer?.cancel();
      _fallbackTimer = null;
      onComplete();
    }

    _completeSubscription = _player.onPlayerComplete.listen((_) {
      completeOnce();
    });

    _fallbackTimer = Timer(_fallbackDuration, completeOnce);

    await _player.play(AssetSource(assetPath));
  }

  Future<void> stop() async {
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    await _completeSubscription?.cancel();
    _completeSubscription = null;
    await _player.stop();
  }

  Future<void> dispose() async {
    await stop();
    await _player.dispose();
  }
}
