import 'dart:async';

import 'package:chronoapp/core/widgets/app_glass_back_button.dart';
import 'package:chronoapp/features/settings/domain/tuning_pitch_label.dart';
import 'package:chronoapp/features/settings/domain/tuning_pitch_stabilizer.dart';
import 'package:chronoapp/features/settings/presentation/services/tuning_audio_session.dart';
import 'package:chronoapp/features/settings/presentation/services/tuning_pitch_detector.dart';
import 'package:chronoapp/features/settings/presentation/services/tuning_reference_tone_player.dart';
import 'package:chronoapp/features/settings/presentation/widgets/tuning_fork_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsTuningForkPage extends StatefulWidget {
  const SettingsTuningForkPage({super.key});

  @override
  State<SettingsTuningForkPage> createState() => _SettingsTuningForkPageState();
}

class _SettingsTuningForkPageState extends State<SettingsTuningForkPage>
    with SingleTickerProviderStateMixin {
  static const _referenceFrequencyHz = TuningReferenceTonePlayer.referenceFrequencyHz;

  final TuningPitchDetector _pitchDetector = TuningPitchDetector();
  final TuningReferenceTonePlayer _tonePlayer = TuningReferenceTonePlayer();
  final TuningPitchStabilizer _pitchStabilizer = TuningPitchStabilizer();

  StreamSubscription<double?>? _frequencySubscription;
  late final AnimationController _tapAnimationController;
  late final Animation<double> _tapScaleAnimation;

  double? _liveFrequencyHz;
  bool _isPlayingReference = false;
  bool _micPermissionDenied = false;

  @override
  void initState() {
    super.initState();
    unawaited(TuningAudioSession.ensureConfigured());
    _tapAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _tapScaleAnimation = Tween<double>(begin: 1, end: 0.94).animate(
      CurvedAnimation(
        parent: _tapAnimationController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutBack,
      ),
    );
    unawaited(_startListening());
  }

  Future<void> _startListening() async {
    final started = await _pitchDetector.start();
    if (!mounted) return;

    setState(() {
      _micPermissionDenied = !started;
    });
    if (!started) return;

    _frequencySubscription ??= _pitchDetector.frequencyStream.listen(
      (frequency) {
        if (!mounted || _isPlayingReference) return;
        setState(() {
          _liveFrequencyHz = frequency;
        });
      },
    );
  }

  Future<void> _onTuningForkTap() async {
    if (_isPlayingReference) return;

    HapticFeedback.mediumImpact();
    await _tapAnimationController.forward();
    await _tapAnimationController.reverse();

    await _pitchDetector.stop();
    _frequencySubscription?.cancel();
    _frequencySubscription = null;

    if (!mounted) return;
    setState(() {
      _isPlayingReference = true;
      _liveFrequencyHz = _referenceFrequencyHz;
    });

    try {
      await _tonePlayer.play(
        onComplete: () {
          if (!mounted) return;
          unawaited(_resumeListeningAfterReference());
        },
      );
    } catch (_) {
      if (!mounted) return;
      await _resumeListeningAfterReference();
    }
  }

  Future<void> _resumeListeningAfterReference() async {
    if (!mounted) return;

    setState(() {
      _isPlayingReference = false;
      _liveFrequencyHz = null;
    });
    _pitchStabilizer.reset();

    await _startListening();
  }

  TuningPitchLabel? get _pitchLabel =>
      _pitchStabilizer.labelForFrequency(_liveFrequencyHz);

  @override
  void dispose() {
    unawaited(_frequencySubscription?.cancel());
    unawaited(_pitchDetector.dispose());
    unawaited(_tonePlayer.dispose());
    _tapAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = theme.scaffoldBackgroundColor;
    final pitchLabel = _pitchLabel;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        toolbarHeight: 44,
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: AppGlassBackButton(),
        ),
        leadingWidth: 56,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FrequencyDisplay(
                pitchLabel: pitchLabel,
                theme: theme,
                scheme: scheme,
              ),
              if (_micPermissionDenied) ...[
                const SizedBox(height: 12),
                Text(
                  'Mikrofonzugriff erforderlich – bitte in den Systemeinstellungen erlauben.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.error.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 36),
              ScaleTransition(
                scale: _tapScaleAnimation,
                child: GestureDetector(
                  onTap: _onTuningForkTap,
                  behavior: HitTestBehavior.opaque,
                  child: TuningForkModel(
                    size: 240,
                    isResonating: _isPlayingReference,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FrequencyDisplay extends StatelessWidget {
  const _FrequencyDisplay({
    required this.pitchLabel,
    required this.theme,
    required this.scheme,
  });

  final TuningPitchLabel? pitchLabel;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    if (pitchLabel == null) {
      return Text(
        '—',
        style: theme.textTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.w300,
          letterSpacing: -1.5,
          color: scheme.onSurface.withValues(alpha: 0.88),
        ),
        textAlign: TextAlign.center,
      );
    }

    final baseStyle = theme.textTheme.displayMedium?.copyWith(
      fontWeight: FontWeight.w300,
      letterSpacing: -1.5,
      color: scheme.onSurface.withValues(alpha: 0.88),
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final noteStyle = theme.textTheme.displaySmall?.copyWith(
      fontWeight: FontWeight.w400,
      color: scheme.onSurface.withValues(alpha: 0.62),
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final symbolStyle = noteStyle?.copyWith(
      color: scheme.primary.withValues(alpha: 0.78),
      fontWeight: FontWeight.w500,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('${pitchLabel!.frequencyHz} Hz', style: baseStyle),
        const SizedBox(width: 14),
        Text(pitchLabel!.noteLetter, style: noteStyle),
        if (pitchLabel!.tuningSymbol != null)
          Text(pitchLabel!.tuningSymbol!, style: symbolStyle),
      ],
    );
  }
}
