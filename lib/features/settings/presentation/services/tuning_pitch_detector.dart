import 'dart:async';
import 'dart:typed_data';

import 'package:chronoapp/features/settings/presentation/services/tuning_audio_session.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:record/record.dart';

class TuningPitchDetector {
  TuningPitchDetector({
    AudioRecorder? recorder,
    PitchDetector? pitchDetector,
  })  : _recorder = recorder ?? AudioRecorder(),
        _pitchDetector = pitchDetector ??
            PitchDetector(
              audioSampleRate: PitchDetector.DEFAULT_SAMPLE_RATE.toDouble(),
              bufferSize: PitchDetector.DEFAULT_BUFFER_SIZE,
            );

  static const _smoothingWindow = 4;

  final AudioRecorder _recorder;
  final PitchDetector _pitchDetector;
  final StreamController<double?> _frequencyController =
      StreamController<double?>.broadcast();

  StreamSubscription<Uint8List>? _recordSubscription;
  final List<double> _recentFrequencies = [];
  bool _isRunning = false;

  Stream<double?> get frequencyStream => _frequencyController.stream;

  Future<bool> start() async {
    if (_isRunning) return true;

    if (!await _recorder.hasPermission()) {
      return false;
    }

    try {
      await TuningAudioSession.ensureConfigured();
      await _recorder.ios?.manageAudioSession(false);

      final stream = await _recorder.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: PitchDetector.DEFAULT_SAMPLE_RATE,
          numChannels: 1,
          autoGain: false,
          echoCancel: false,
          noiseSuppress: false,
          androidConfig: const AndroidRecordConfig(
            audioSource: AndroidAudioSource.mic,
            speakerphone: true,
          ),
        ),
      );

      _isRunning = true;
      _recentFrequencies.clear();

      final bufferSize = PitchDetector.DEFAULT_BUFFER_SIZE * 2;
      final buffer = <int>[];

      _recordSubscription = stream.listen(
        (chunk) {
          buffer.addAll(chunk);
          while (buffer.length >= bufferSize) {
            final sample = Uint8List.fromList(buffer.sublist(0, bufferSize));
            buffer.removeRange(0, bufferSize);
            unawaited(_processSample(sample));
          }
        },
        onError: (_) {
          _frequencyController.add(null);
        },
      );

      return true;
    } catch (_) {
      _isRunning = false;
      return false;
    }
  }

  Future<void> _processSample(Uint8List sample) async {
    final floatBuffer = _pcm16LeToFloat(sample);
    final result = await _pitchDetector.getPitchFromFloatBuffer(floatBuffer);
    if (!result.pitched || result.pitch <= 0) {
      return;
    }

    _recentFrequencies.add(result.pitch);
    if (_recentFrequencies.length > _smoothingWindow) {
      _recentFrequencies.removeAt(0);
    }

    final average = _recentFrequencies.reduce((a, b) => a + b) /
        _recentFrequencies.length;
    _frequencyController.add(average);
  }

  /// Korrekte PCM16-LE-Konvertierung – die Library-Extension nutzt nur das
  /// niederwertige Byte und liefert damit kein brauchbares Signal.
  static List<double> _pcm16LeToFloat(Uint8List bytes) {
    final byteData = bytes.buffer.asByteData(
      bytes.offsetInBytes,
      bytes.lengthInBytes,
    );
    final sampleCount = bytes.lengthInBytes ~/ 2;
    return List<double>.generate(
      sampleCount,
      (index) => byteData.getInt16(index * 2, Endian.little) / 32768.0,
      growable: false,
    );
  }

  Future<void> stop() async {
    if (!_isRunning) return;

    await _recordSubscription?.cancel();
    _recordSubscription = null;
    _recentFrequencies.clear();

    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }

    _isRunning = false;
  }

  Future<void> dispose() async {
    await stop();
    await _frequencyController.close();
    await _recorder.dispose();
  }
}
