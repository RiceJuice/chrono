import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/app_date_time.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../login/presentation/pages/music_lessons/music_lesson_editor.dart';
import '../../../login/presentation/providers/profile_gate_provider.dart';
import '../../../music_lessons/domain/music_lesson_schedule.dart';
import '../helpers/settings_icons.dart';
import 'settings_island.dart';
import 'settings_section_label.dart';
import 'settings_tile.dart';

class SettingsMusicLessonsSection extends ConsumerStatefulWidget {
  const SettingsMusicLessonsSection({super.key});

  @override
  ConsumerState<SettingsMusicLessonsSection> createState() =>
      _SettingsMusicLessonsSectionState();
}

class _SettingsMusicLessonsSectionState
    extends ConsumerState<SettingsMusicLessonsSection> {
  bool _busy = false;
  MusicLessonKind? _saving;

  Future<void> _edit(MusicLessonKind kind, MusicLesson? saved) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final edit = await showMusicLessonEditor(context, kind, saved);
      if (!mounted || edit == null) return;
      setState(() => _saving = kind);
      await ref.read(profileGateProvider).saveMusicLesson(kind, edit.lesson);
    } catch (_) {
      if (!mounted) return;
      showAppToast(
        context,
        'Der Musiktermin konnte nicht gespeichert werden. Bitte versuch es erneut.',
        kind: AppToastKind.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _saving = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedule = ref.watch(
      profileGateDataProvider.select((profile) => profile.musicLessons),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SettingsSectionLabel(title: 'Musikunterricht'),
        SettingsIsland(
          children: [
            _tile(MusicLessonKind.voice, schedule?.voice),
            _tile(MusicLessonKind.instrument, schedule?.instrument),
          ],
        ),
      ],
    );
  }

  Widget _tile(MusicLessonKind kind, MusicLesson? lesson) {
    return SettingsTile(
      title: kind.editorTitle,
      icon: kind == MusicLessonKind.voice
          ? SettingsIcons.voice
          : SettingsIcons.choir,
      subtitle: lesson == null
          ? 'Eintragen'
          : '${AppDateTime.fullWeekdayLabels[lesson.weekday]?.substring(0, 2)}, '
                '${formatMusicLessonTime(lesson.startMinute)} Uhr',
      enabled: !_busy,
      onTap: () => _edit(kind, lesson),
      trailing: _saving == kind
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
    );
  }
}
