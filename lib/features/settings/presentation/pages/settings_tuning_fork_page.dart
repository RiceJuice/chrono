import 'dart:async';

import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/widgets/app_glass_back_button.dart';
import 'package:chronoapp/features/settings/domain/tuning_pitch_label.dart';
import 'package:chronoapp/features/settings/presentation/services/tuning_reference_tone_player.dart';
import 'package:chronoapp/features/settings/presentation/widgets/tuning_fork_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

enum _Note {
  c('C', 0),
  d('D', 2),
  e('E', 4),
  f('F', 5),
  g('G', 7),
  a('A', 9),
  h('H', 11);

  const _Note(this.label, this.semitones);

  final String label;
  final int semitones;
}

enum _Accidental {
  flat('B-Vorzeichen', -1),
  natural('Ohne Vorzeichen', 0),
  sharp('Kreuz', 1);

  const _Accidental(this.label, this.semitones);
  final String label;
  final int semitones;
}

const _motionDuration = Duration(milliseconds: 350);
const _motionCurve = Curves.easeOutCubic;

class SettingsTuningForkPage extends StatefulWidget {
  const SettingsTuningForkPage({super.key});

  @override
  State<SettingsTuningForkPage> createState() => _SettingsTuningForkPageState();
}

class _SettingsTuningForkPageState extends State<SettingsTuningForkPage>
    with SingleTickerProviderStateMixin {
  static const _minOctave = 2;
  static const _maxOctave = 6;
  static final _frequencyFormat = NumberFormat('0.##', 'de');

  TuningReferenceTonePlayer? _tonePlayer;
  late final AnimationController _strike;

  _Note _note = _Note.a;
  _Accidental _accidental = _Accidental.natural;
  int _octave = 4;
  bool _choosingNote = true;
  bool _starting = false;
  bool _playing = false;

  double get _frequency => tuningTemperedFrequencyHzForMidi(
    12 * (_octave + 1) + _note.semitones + _accidental.semitones,
  );

  @override
  void initState() {
    super.initState();
    _strike = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
      value: 1,
    );
  }

  void _selectNote(_Note note) {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _note = note;
      _choosingNote = false;
    });
  }

  void _showNotes() {
    unawaited(HapticFeedback.selectionClick());
    setState(() => _choosingNote = true);
  }

  void _changeOctave(int step) {
    unawaited(HapticFeedback.selectionClick());
    setState(() => _octave += step);
  }

  void _changeAccidental(_Accidental accidental) {
    if (_accidental == accidental) return;
    unawaited(HapticFeedback.selectionClick());
    setState(() => _accidental = accidental);
  }

  Future<void> _strikeFork() async {
    if (_starting) return;

    final frequency = _frequency;
    AppHaptics.medium();
    if (!MediaQuery.disableAnimationsOf(context)) {
      unawaited(_strike.forward(from: 0));
    }
    setState(() {
      _starting = true;
      _playing = false;
    });

    var finished = false;
    try {
      await (_tonePlayer ??= TuningReferenceTonePlayer()).play(
        frequency,
        onComplete: () {
          finished = true;
          if (mounted) setState(() => _playing = false);
        },
      );
      if (mounted && !finished) setState(() => _playing = true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Der Ton konnte nicht abgespielt werden.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  void dispose() {
    _strike.dispose();
    unawaited(_tonePlayer?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = theme.scaffoldBackgroundColor;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _motionDuration;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leadingWidth: 56,
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: AppGlassBackButton(),
        ),
        title: const Text('Stimmgabel'),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stageSize = (constraints.maxHeight * 0.49).clamp(
              165.0,
              320.0,
            );
            return CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Expanded(
                              child: Center(
                                child: _buildInstrument(
                                  context,
                                  stageSize,
                                  duration,
                                ),
                              ),
                            ),
                            _buildNotePanel(context, duration),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInstrument(
    BuildContext context,
    double size,
    Duration duration,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            label: 'Stimmgabel anschlagen',
            onTap: _strikeFork,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                excludeFromSemantics: true,
                customBorder: const CircleBorder(),
                onTap: _strikeFork,
                child: SizedBox.square(
                  dimension: size,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          scheme.primary.withValues(alpha: 0.14),
                          scheme.primary.withValues(alpha: 0),
                        ],
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: scheme.outlineVariant.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                          ),
                        ),
                        TuningForkModel(strike: _strike),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Text(
            '${_frequencyFormat.format(_frequency)} Hz',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 3),
          AnimatedSwitcher(
            duration: duration,
            child: Text(
              _playing ? 'Klingt aus' : 'Zum Anschlagen antippen',
              key: ValueKey(_playing),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotePanel(BuildContext context, Duration duration) {
    final scheme = Theme.of(context).colorScheme;
    final notes = _choosingNote
        ? _Note.values
        : [..._Note.values.where((note) => note != _note), _note];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                _choosingNote ? 'Grundton wählen' : 'Gewählter Ton',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            if (!_choosingNote)
              TextButton(
                onPressed: _showNotes,
                child: const Text('Ton wechseln'),
              )
            else
              const SizedBox(height: 48),
          ],
        ),
        SizedBox(
          height: 76,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = (constraints.maxWidth - 6 * 6) / 7;
              return Stack(
                clipBehavior: Clip.none,
                fit: StackFit.expand,
                children: [
                  for (final note in notes)
                    AnimatedAlign(
                      key: ValueKey(note),
                      duration: duration,
                      curve: _motionCurve,
                      alignment: !_choosingNote && note == _note
                          ? const Alignment(0, -0.75)
                          : Alignment((note.index - 3) / 3, 0.6),
                      child: IgnorePointer(
                        ignoring: !_choosingNote && note != _note,
                        child: ExcludeFocus(
                          excluding: !_choosingNote && note != _note,
                          child: ExcludeSemantics(
                            excluding: !_choosingNote && note != _note,
                            child: AnimatedOpacity(
                              duration: duration,
                              curve: _motionCurve,
                              opacity: _choosingNote || note == _note ? 1 : 0,
                              child: _NoteTile(
                                note: note,
                                accidental: _accidental,
                                octave: _octave,
                                selected: note == _note,
                                expanded: !_choosingNote && note == _note,
                                width: _choosingNote || note != _note
                                    ? tileWidth
                                    : 108,
                                duration: duration,
                                onTap: !_choosingNote && note == _note
                                    ? _showNotes
                                    : () => _selectNote(note),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        AnimatedSize(
          duration: duration,
          curve: _motionCurve,
          alignment: Alignment.topCenter,
          child: _choosingNote
              ? const SizedBox(width: double.infinity)
              : Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _ControlGroup(
                      label: 'Oktave',
                      children: [
                        IconButton(
                          tooltip: 'Tiefere Oktave',
                          onPressed: _octave > _minOctave
                              ? () => _changeOctave(-1)
                              : null,
                          icon: const Icon(Icons.remove_rounded),
                        ),
                        SizedBox(
                          width: 24,
                          child: Text('$_octave', textAlign: TextAlign.center),
                        ),
                        IconButton(
                          tooltip: 'Höhere Oktave',
                          onPressed: _octave < _maxOctave
                              ? () => _changeOctave(1)
                              : null,
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                    _ControlGroup(
                      label: 'Vorzeichen',
                      children: [
                        for (final accidental in _Accidental.values)
                          IconButton(
                            tooltip: accidental.label,
                            isSelected: _accidental == accidental,
                            style: IconButton.styleFrom(
                              foregroundColor: _accidental == accidental
                                  ? scheme.onPrimaryContainer
                                  : scheme.onSurfaceVariant,
                              backgroundColor: _accidental == accidental
                                  ? scheme.primaryContainer
                                  : Colors.transparent,
                            ),
                            onPressed: () => _changeAccidental(accidental),
                            icon: _AccidentalMark(accidental),
                          ),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({
    required this.note,
    required this.accidental,
    required this.octave,
    required this.selected,
    required this.expanded,
    required this.width,
    required this.duration,
    required this.onTap,
  });

  final _Note note;
  final _Accidental accidental;
  final int octave;
  final bool selected;
  final bool expanded;
  final double width;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const radius = BorderRadius.all(Radius.circular(16));
    final showAccidental = expanded && accidental != _Accidental.natural;
    return Semantics(
      button: true,
      selected: selected,
      label: expanded
          ? '${note.label}${showAccidental ? ' ${accidental.label}' : ''}, Oktave $octave, Ton wechseln'
          : note.label,
      child: AnimatedContainer(
        duration: duration,
        curve: _motionCurve,
        width: width,
        height: 54,
        decoration: BoxDecoration(
          color: selected
              ? Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.17),
                  scheme.surfaceContainerLow,
                )
              : scheme.surfaceContainerLow,
          borderRadius: radius,
          border: Border.all(
            color: selected
                ? scheme.primary
                : scheme.outlineVariant.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.24),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ExcludeSemantics(
                    child: AnimatedDefaultTextStyle(
                      duration: duration,
                      curve: _motionCurve,
                      style: (theme.textTheme.titleMedium ?? const TextStyle())
                          .copyWith(
                            fontSize: expanded ? 28 : 17,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                      child: Text.rich(
                        TextSpan(
                          text: note.label,
                          children: [
                            if (showAccidental)
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: _AccidentalMark(
                                  accidental,
                                  color: scheme.onSurface,
                                ),
                              ),
                            if (expanded)
                              TextSpan(
                                text: ' $octave',
                                style: const TextStyle(fontSize: 15),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlGroup extends StatelessWidget {
  const _ControlGroup({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Row(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _AccidentalMark extends StatelessWidget {
  const _AccidentalMark(this.accidental, {this.color});

  final _Accidental accidental;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(14, 22),
      painter: _AccidentalPainter(
        accidental,
        color ??
            IconTheme.of(context).color ??
            Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _AccidentalPainter extends CustomPainter {
  const _AccidentalPainter(this.accidental, this.color);

  final _Accidental accidental;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    switch (accidental) {
      case _Accidental.flat:
        path
          ..moveTo(4, 2)
          ..lineTo(4, 20)
          ..cubicTo(16, 14, 10, 8, 4, 12);
      case _Accidental.natural:
        path
          ..moveTo(4, 2)
          ..lineTo(4, 15)
          ..lineTo(10, 13)
          ..moveTo(4, 9)
          ..lineTo(10, 7)
          ..lineTo(10, 20);
      case _Accidental.sharp:
        path
          ..moveTo(5, 3)
          ..lineTo(4, 20)
          ..moveTo(10, 2)
          ..lineTo(9, 19)
          ..moveTo(2, 10)
          ..lineTo(12, 7)
          ..moveTo(2, 15)
          ..lineTo(12, 12);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _AccidentalPainter oldDelegate) =>
      oldDelegate.accidental != accidental || oldDelegate.color != color;
}
