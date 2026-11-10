import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class TuningReferenceTonePlayer {
  TuningReferenceTonePlayer({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  static const _duration = Duration(seconds: 5);

  final AudioPlayer _player;
  StreamSubscription<void>? _completion;
  Timer? _fallback;
  Future<void>? _starting;
  double? _loadedFrequency;
  bool _disposed = false;

  Future<void> play(double frequency, {required VoidCallback onComplete}) {
    if (_disposed) return Future.value();

    return _starting ??= _play(frequency, onComplete).whenComplete(() {
      _starting = null;
    });
  }

  Future<void> _play(double frequency, VoidCallback onComplete) async {
    await _clearCompletion();
    await _player.stop();

    if (_loadedFrequency != frequency) {
      _loadedFrequency = null;
      final wave = await compute(_renderForkWave, frequency);
      if (_disposed) return;

      await _player.setAudioContext(
        AudioContextConfig(
          route: AudioContextConfigRoute.speaker,
          respectSilence: false,
        ).build(),
      );
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setSource(BytesSource(wave, mimeType: 'audio/wav'));
      _loadedFrequency = frequency;
    }
    if (_disposed) return;

    var completed = false;
    void finish() {
      if (completed || _disposed) return;
      completed = true;
      _fallback?.cancel();
      onComplete();
    }

    _completion = _player.onPlayerComplete.listen((_) => finish());
    try {
      await _player.resume();
      if (!completed && !_disposed) {
        _fallback = Timer(
          _duration + const Duration(milliseconds: 250),
          finish,
        );
      }
    } catch (_) {
      await _clearCompletion();
      rethrow;
    }
  }

  Future<void> _clearCompletion() async {
    _fallback?.cancel();
    _fallback = null;
    await _completion?.cancel();
    _completion = null;
  }

  Future<void> dispose() async {
    _disposed = true;
    try {
      await _starting;
    } catch (_) {
      // The caller of play handles playback errors.
    }
    await _clearCompletion();
    await _player.dispose();
  }
}

Uint8List _renderForkWave(double frequency) {
  const sampleRate = 32000;
  final sampleCount =
      sampleRate * TuningReferenceTonePlayer._duration.inSeconds;
  final dataSize = sampleCount * 2;
  final wave = ByteData(44 + dataSize)
    ..setUint32(0, 0x52494646) // RIFF
    ..setUint32(4, 36 + dataSize, Endian.little)
    ..setUint32(8, 0x57415645) // WAVE
    ..setUint32(12, 0x666D7420) // fmt
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little) // PCM
    ..setUint16(22, 1, Endian.little)
    ..setUint32(24, sampleRate, Endian.little)
    ..setUint32(28, sampleRate * 2, Endian.little)
    ..setUint16(32, 2, Endian.little)
    ..setUint16(34, 16, Endian.little)
    ..setUint32(36, 0x64617461) // data
    ..setUint32(40, dataSize, Endian.little);

  final cyclesPerSample = 2 * math.pi * frequency / sampleRate;
  final decayTime = (1.15 * math.pow(440 / frequency, 0.16)).clamp(0.8, 1.5);
  final bodyDecay = math.exp(-1 / (sampleRate * decayTime));
  final strikeDecay = math.exp(-1 / (sampleRate * 0.035));
  final strikeMode = frequency * 6.25 < sampleRate / 2 ? 0.075 : 0.0;
  var body = 1.0;
  var strike = strikeMode;

  for (var i = 0; i < sampleCount; i++) {
    final phase = i * cyclesPerSample;
    final attack = math.min(1, i / (sampleRate * 0.002));
    final tail = math.min(1, (sampleCount - 1 - i) / (sampleRate * 0.18));
    final sample =
        attack *
        tail *
        (0.62 * body * math.sin(phase) + strike * math.sin(6.25 * phase));
    wave.setInt16(44 + 2 * i, (sample * 32767).round(), Endian.little);
    body *= bodyDecay;
    strike *= strikeDecay;
  }
  return wave.buffer.asUint8List();
}
