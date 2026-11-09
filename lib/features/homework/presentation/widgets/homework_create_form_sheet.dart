import 'dart:async';

import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:chronoapp/features/calendar/presentation/providers/filter/calendar/calendar_filtered_entries_providers.dart';
import 'package:chronoapp/features/calendar/presentation/providers/subjects_providers.dart';
import 'package:chronoapp/features/homework/domain/models/homework_task.dart';
import 'package:chronoapp/features/homework/domain/next_lesson_for_subject.dart';
import 'package:chronoapp/features/homework/presentation/helpers/homework_creation_undo.dart';
import 'package:chronoapp/features/homework/presentation/helpers/homework_due_display.dart';
import 'package:chronoapp/features/homework/presentation/providers/homework_due_providers.dart';
import 'package:chronoapp/features/homework/presentation/providers/homework_providers.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_task_form_sheet.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_child_permissions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract final class HomeworkCreateFormSheet {
  static const _channel = MethodChannel('chrono/homework_create');

  static Future<void> show(BuildContext context) async {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      if (await _showNative(context) || !context.mounted) return;
    }
    await HomeworkTaskFormSheet.show(context);
  }

  static Future<bool> _showNative(BuildContext context) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final colors = Theme.of(context).colorScheme;
    final profileId = container.read(effectiveHomeworkProfileIdProvider);
    final notifier = container.read(homeworkTasksProvider.notifier);
    String? createdTaskId;
    bool saving = false;

    _channel.setMethodCallHandler((call) async {
      if (call.method != 'save') throw MissingPluginException();
      const saveError = 'Aufgabe konnte nicht gespeichert werden.';
      if (saving || createdTaskId != null || !context.mounted) return saveError;
      if (container.read(isGuardianHomeworkReadOnlyProvider) ||
          container.read(effectiveHomeworkProfileIdProvider) != profileId) {
        return saveError;
      }

      final args = Map<String, Object?>.from(call.arguments as Map);
      final title = (args['title'] as String).trim();
      final notes = (args['notes'] as String).trim();
      final subjectId = args['subjectId'] as String?;
      final nextLesson = args['nextLesson'] == true;
      final date = args['day'] as String?;
      if (title.isEmpty) return 'Bitte gib einen Titel ein.';
      final due = resolveHomeworkFormDue(
        entries: container
            .read(filteredCalendarAllEntriesProvider)
            .asData
            ?.value,
        subjectId: subjectId,
        nextLesson: nextLesson,
        day: date == null ? null : DateTime.tryParse(date),
      );
      if (due.dueAt == null) {
        return nextLesson
            ? 'Für dieses Fach ist keine kommende Stunde verfügbar.'
            : 'Bitte wähle einen Abgabetag.';
      }

      saving = true;
      try {
        createdTaskId = await notifier.addTask(
          title: title,
          description: notes.isEmpty ? null : notes,
          subjectId: subjectId,
          dueAt: due.dueAt,
          dueSource: due.dueSource,
        );
        return createdTaskId == null ? saveError : null;
      } catch (_) {
        return saveError;
      } finally {
        saving = false;
      }
    });

    Future<void> sendOptions(Map<String, Object?> options) async {
      try {
        await _channel.invokeMethod<void>('update', options);
      } on MissingPluginException {
        // The Flutter form handles builds without the native sheet.
      } on PlatformException {
        // A closing sheet no longer needs option updates.
      }
    }

    final subscription = container.listen(
      _nativeOptionsProvider,
      (_, options) => unawaited(sendOptions(options)),
    );
    AppModalSheetTracker.retainMainNavigationHidden();
    try {
      await _channel.invokeMethod<void>(
        'present',
        container.read(_nativeOptionsProvider),
      );
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    } finally {
      subscription.close();
      _channel.setMethodCallHandler(null);
      AppModalSheetTracker.releaseMainNavigationHidden();
    }

    if (createdTaskId case final id?
        when messenger.mounted && context.mounted) {
      unawaited(
        offerHomeworkCreationUndo(
          messenger: messenger,
          colors: colors,
          deleteTask: () => notifier.deleteTask(id),
        ),
      );
    }
    return true;
  }
}

final _nativeOptionsProvider = Provider<Map<String, Object?>>((ref) {
  final subjects = ref.watch(subjectsListProvider);
  final entries = ref.watch(filteredCalendarAllEntriesProvider);
  final currentSubject = ref.watch(currentSubjectIdProvider);
  final now = DateTime.now();
  return {
    'currentSubjectId': currentSubject,
    'subjectsLoading': subjects.isLoading,
    'subjectsFailed': subjects.hasError,
    'lessonsLoading': entries.isLoading,
    'lessonsFailed': entries.hasError,
    'subjects': [
      for (final subject in subjects.value ?? [])
        {
          'id': subject.id,
          'name': subject.name,
          if (pickNextLessonForSubject(
                entries: entries.value ?? [],
                subjectId: subject.id,
                now: now,
              )
              case final lesson?)
            'nextLesson': formatHomeworkDueLabel(
              dueAt: lesson.startTime,
              dueSource: HomeworkDueSource.nextLesson,
            ),
        },
    ],
  };
});
