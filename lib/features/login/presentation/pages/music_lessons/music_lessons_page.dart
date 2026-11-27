import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/time/app_date_time.dart';
import '../../../../music_lessons/domain/music_lesson_schedule.dart';
import '../../../domain/models/login_flow_step.dart';
import '../../providers/profile_gate_provider.dart';
import '../../routes/login_paths.dart';
import '../../widgets/login_step_scaffold.dart';
import 'music_lesson_editor.dart';

class MusicLessonsPage extends ConsumerStatefulWidget {
  const MusicLessonsPage({super.key});

  @override
  ConsumerState<MusicLessonsPage> createState() => _MusicLessonsPageState();
}

class _MusicLessonsPageState extends ConsumerState<MusicLessonsPage> {
  final _lessons = <MusicLessonKind, MusicLesson>{};
  bool _editing = false;
  bool _saving = false;
  bool _saveFailed = false;

  @override
  void initState() {
    super.initState();
    final schedule = ref.read(profileGateProvider).data.musicLessons;
    for (final lesson in schedule?.lessons ?? const <MusicLesson>[]) {
      _lessons[lesson.kind] = lesson;
    }
  }

  Future<void> _edit(MusicLessonKind kind) async {
    if (_editing || _saving) return;
    setState(() => _editing = true);
    try {
      final result = await showMusicLessonEditor(context, kind, _lessons[kind]);
      if (!mounted || result == null) return;
      setState(() {
        final lesson = result.lesson;
        if (lesson == null) {
          _lessons.remove(kind);
        } else {
          _lessons[kind] = lesson;
        }
        _saveFailed = false;
      });
    } finally {
      if (mounted) setState(() => _editing = false);
    }
  }

  Future<bool> _save(VoidCallback goNext) async {
    if (_saving || _editing) return false;
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    try {
      await ref
          .read(profileGateProvider)
          .saveMusicLessons(
            voice: _lessons[MusicLessonKind.voice],
            instrument: _lessons[MusicLessonKind.instrument],
          );
      if (mounted) goNext();
      return true;
    } catch (_) {
      if (mounted) setState(() => _saveFailed = true);
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasLessons = _lessons.isNotEmpty;
    return LoginStepScaffold(
      step: LoginFlowStep.musicLessons,
      titleOverride: 'Musikunterricht',
      subtitleOverride:
          'Kennst du schon Wochentag und Uhrzeit? Trag deine Termine jetzt ein. Chrono übernimmt sie für dich in den Schulkalender.',
      nextPath: LoginPaths.choir,
      contentMaxWidth: 460,
      primaryButtonMaxWidth: 460,
      showPrimaryButton: hasLessons,
      submitLabel: 'Speichern & weiter',
      submitBusy: _saving,
      onAsyncProceed: (goNext) async {
        if (!await _save(goNext)) throw const LoginStepErrorAlreadyShown();
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final kind in MusicLessonKind.values) ...[
              _LessonCard(
                kind: kind,
                lesson: _lessons[kind],
                onTap: _editing || _saving ? null : () => _edit(kind),
              ),
              const SizedBox(height: 12),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.event_repeat_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Wöchentlich während der Schulzeit. Ferien und Feiertage bleiben frei.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_saveFailed) ...[
              const SizedBox(height: 14),
              Semantics(
                liveRegion: true,
                child: Text(
                  'Das Speichern hat nicht geklappt. Prüfe deine Internetverbindung und versuch es noch einmal.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.error,
                  ),
                ),
              ),
            ],
            if (!hasLessons) ...[
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.center,
                child: _saving
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : TextButton(
                        onPressed: _editing
                            ? null
                            : () => _save(() => context.go(LoginPaths.choir)),
                        child: const Text('Ich kenne meine Termine noch nicht'),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.kind, required this.lesson, this.onTap});

  final MusicLessonKind kind;
  final MusicLesson? lesson;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final saved = lesson;
    final isVoice = kind == MusicLessonKind.voice;
    final accent = LoginFlowStep.musicLessons.accentColor;
    final color = theme.brightness == Brightness.dark
        ? const Color(0xFFC9B2FF)
        : accent;
    final time = saved == null
        ? null
        : formatMusicLessonTime(saved.startMinute);
    final instrument = saved?.instrument;
    final details = saved == null
        ? '${kind.standardMinutes} Min. · Termin eintragen'
        : '${instrument == null ? '' : '$instrument · '}${AppDateTime.fullWeekdayLabels[saved.weekday]}, $time Uhr · ${saved.durationMinutes} Min.';
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: color.withValues(alpha: saved == null ? .2 : .48),
      ),
    );

    return Material(
      color: Color.alphaBlend(color.withValues(alpha: .06), scheme.surface),
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  isVoice ? Icons.graphic_eq_rounded : Icons.music_note_rounded,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kind.editorTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      details,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                saved == null ? Icons.add_rounded : Icons.edit_outlined,
                size: 20,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
