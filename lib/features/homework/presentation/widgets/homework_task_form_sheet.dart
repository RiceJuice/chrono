import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:chronoapp/features/calendar/presentation/providers/filter/calendar/calendar_filtered_entries_providers.dart';
import 'package:chronoapp/features/homework/domain/models/homework_task.dart';
import 'package:chronoapp/features/homework/domain/next_lesson_for_subject.dart';
import 'package:chronoapp/features/homework/presentation/providers/homework_due_providers.dart';
import 'package:chronoapp/features/homework/presentation/providers/homework_providers.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_due_section.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_form_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeworkTaskFormSheet extends ConsumerStatefulWidget {
  const HomeworkTaskFormSheet({super.key, this.embedded = false, this.task});

  final bool embedded;
  final HomeworkTask? task;

  static Future<void> show(BuildContext context, {HomeworkTask? task}) {
    return AppModalSheet.show<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      sheetAnimationStyle: kAppModalSheetMotion,
      builder: (sheetContext) {
        return AppModalSheetChrome(
          constraints: appModalHomeworkFormSheetConstraints(sheetContext),
          child: HomeworkTaskFormSheet(task: task),
        );
      },
    );
  }

  @override
  ConsumerState<HomeworkTaskFormSheet> createState() =>
      _HomeworkTaskFormSheetState();
}

class _HomeworkTaskFormSheetState extends ConsumerState<HomeworkTaskFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedSubjectId;
  bool _dueNextLesson = true;
  DateTime? _selectedDay;
  bool _saving = false;
  bool _autoSubjectApplied = false;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    if (task != null) {
      _titleController.text = task.title;
      _descriptionController.text = task.displayDescription;
      _selectedSubjectId = task.subjectId;
      _dueNextLesson = task.dueSource == HomeworkDueSource.nextLesson;
      _selectedDay = task.dueAt == null
          ? null
          : DateUtils.dateOnly(task.dueAt!.toLocal());
      _autoSubjectApplied = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyAutoSubject());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _applyAutoSubject() {
    if (_autoSubjectApplied || _selectedSubjectId != null) return;
    final subjectId = ref.read(currentSubjectIdProvider);
    if (subjectId == null || subjectId.isEmpty) return;
    setState(() {
      _selectedSubjectId = subjectId;
      _autoSubjectApplied = true;
    });
  }

  void _onSubjectChanged(String? subjectId) {
    setState(() {
      _autoSubjectApplied = true;
      final hadSubject = _selectedSubjectId != null;
      _selectedSubjectId = subjectId;
      if (subjectId == null || subjectId.isEmpty) {
        _dueNextLesson = false;
      } else if (!hadSubject && _selectedDay == null) {
        _dueNextLesson = true;
      }
    });
  }

  bool get _canCreate {
    if (_titleController.text.trim().isEmpty) return false;
    if (!_dueNextLesson) {
      return _selectedDay != null;
    }

    final subjectId = _selectedSubjectId?.trim();
    if (subjectId == null || subjectId.isEmpty) return false;

    final nextLesson = ref.read(nextLessonForSubjectProvider(subjectId));
    return nextLesson.maybeWhen(
      data: (lesson) => lesson != null,
      orElse: () => false,
    );
  }

  ({DateTime? dueAt, HomeworkDueSource? dueSource}) _resolveDueFields() {
    if (!_dueNextLesson) {
      final day = _selectedDay!;
      final lesson = _selectedSubjectId == null
          ? null
          : ref
                .read(
                  lessonForSubjectOnDayProvider((
                    subjectId: _selectedSubjectId!,
                    day: day,
                  )),
                )
                .asData
                ?.value;
      return (
        dueAt:
            lesson?.startTime.toLocal() ??
            DateTime(day.year, day.month, day.day, 23, 59),
        dueSource: HomeworkDueSource.customDate,
      );
    }
    return _resolveNextLessonDue();
  }

  ({DateTime? dueAt, HomeworkDueSource? dueSource}) _resolveNextLessonDue() {
    final subjectId = _selectedSubjectId?.trim();
    if (subjectId == null || subjectId.isEmpty) {
      return (dueAt: null, dueSource: null);
    }

    final entries = ref.read(filteredCalendarAllEntriesProvider).asData?.value;
    if (entries == null) return (dueAt: null, dueSource: null);

    final lesson = pickNextLessonForSubject(
      entries: entries,
      subjectId: subjectId,
    );
    if (lesson == null) return (dueAt: null, dueSource: null);

    return (
      dueAt: lesson.startTime.toLocal(),
      dueSource: HomeworkDueSource.nextLesson,
    );
  }

  Future<void> _onCreate() async {
    if (_saving || !_canCreate) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final title = _titleController.text.trim();
    final dueFields = _resolveDueFields();

    setState(() => _saving = true);
    try {
      final notifier = ref.read(homeworkTasksProvider.notifier);
      String? createdTaskId;
      if (widget.task != null) {
        await notifier.updateTask(
          widget.task!,
          title: title,
          description: _descriptionController.text.trim(),
          subjectId: _selectedSubjectId,
          dueAt: dueFields.dueAt,
          dueSource: dueFields.dueSource,
        );
      } else {
        createdTaskId = await notifier.addTask(
          title: title,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          subjectId: _selectedSubjectId,
          dueAt: dueFields.dueAt,
          dueSource: dueFields.dueSource,
        );
        if (createdTaskId == null) {
          throw StateError('No homework task was created.');
        }
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final colors = Theme.of(context).colorScheme;
      final route = ModalRoute.of(context);
      Navigator.of(context).pop();
      if (createdTaskId case final taskId?) {
        await route?.completed;
        if (!messenger.mounted) return;
        await _offerUndo(
          messenger: messenger,
          colors: colors,
          deleteTask: () => notifier.deleteTask(taskId),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aufgabe konnte nicht gespeichert werden.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _offerUndo({
    required ScaffoldMessengerState messenger,
    required ColorScheme colors,
    required Future<void> Function() deleteTask,
  }) async {
    const message = 'Aufgabe erstellt';
    const action = 'Rückgängig';

    Future<void> undo() async {
      try {
        await deleteTask();
      } catch (_) {
        if (!messenger.mounted) return;
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Aufgabe konnte nicht gelöscht werden.'),
          ),
        );
      }
    }

    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      try {
        final tapped = await const MethodChannel(
          'chrono/homework_undo',
        ).invokeMethod<bool>('show', {'message': message, 'action': action});
        if (tapped == true) await undo();
        return;
      } on MissingPluginException {
        // A running build may not have the native handler yet.
      } on PlatformException {
        // Fall back when the native window is unavailable.
      }
    }

    if (!messenger.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        elevation: 1,
        backgroundColor: colors.surfaceContainerHighest,
        showCloseIcon: false,
        content: Text(message, style: TextStyle(color: colors.onSurface)),
        action: SnackBarAction(
          label: action,
          textColor: colors.onSurfaceVariant,
          onPressed: undo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(nextLessonForSubjectProvider(_selectedSubjectId));
    if (_selectedSubjectId != null && _selectedDay != null) {
      ref.watch(
        lessonForSubjectOnDayProvider((
          subjectId: _selectedSubjectId!,
          day: _selectedDay!,
        )),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    final fieldDecoration = InputDecoration(
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      filled: false,
      isDense: true,
      contentPadding: EdgeInsets.zero,
      hintStyle: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
    );

    return ColoredBox(
      color: homeworkUsesCupertino(context)
          ? CupertinoColors.systemGroupedBackground.resolveFrom(context)
          : scheme.surface,
      child: SafeArea(
        top: false,
        bottom: true,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!widget.embedded)
                HomeworkFormModalHeader(
                  title: widget.task == null
                      ? 'Neue Aufgabe'
                      : 'Aufgabe bearbeiten',
                ),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    widget.embedded ? AppSpacing.l : AppSpacing.s,
                    AppSpacing.xl,
                    AppSpacing.l + bottomInset,
                  ),
                  children: [
                    const HomeworkFormSectionLabel(label: 'Titel'),
                    HomeworkFormGroup(
                      children: [
                        HomeworkFormField(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.l,
                            AppSpacing.l + 2,
                            AppSpacing.l,
                            AppSpacing.l + 2,
                          ),
                          child: homeworkUsesCupertino(context)
                              ? CupertinoTextField(
                                  controller: _titleController,
                                  placeholder: 'Was ist zu tun?',
                                  padding: EdgeInsets.zero,
                                  decoration: null,
                                  minLines: 1,
                                  maxLines: 3,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  textInputAction: TextInputAction.next,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                  onChanged: (_) => setState(() {}),
                                )
                              : TextFormField(
                                  controller: _titleController,
                                  autofocus: !widget.embedded,
                                  minLines: 1,
                                  maxLines: 3,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  textInputAction: TextInputAction.next,
                                  scrollPadding: EdgeInsets.only(
                                    bottom: bottomInset + 120,
                                  ),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                  decoration: fieldDecoration.copyWith(
                                    hintText: 'Was ist zu tun?',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Bitte einen Titel eingeben.';
                                    }
                                    return null;
                                  },
                                  onChanged: (_) => setState(() {}),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const HomeworkFormSectionLabel(label: 'Notizen · optional'),
                    HomeworkFormGroup(
                      children: [
                        HomeworkFormField(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.l,
                            AppSpacing.l + 2,
                            AppSpacing.l,
                            AppSpacing.l + 2,
                          ),
                          child: homeworkUsesCupertino(context)
                              ? CupertinoTextField(
                                  controller: _descriptionController,
                                  placeholder:
                                      'Notizen, Seiten oder weitere Details',
                                  padding: EdgeInsets.zero,
                                  decoration: null,
                                  minLines: 2,
                                  maxLines: 5,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  textInputAction: TextInputAction.newline,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                )
                              : TextFormField(
                                  controller: _descriptionController,
                                  minLines: 2,
                                  maxLines: 5,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  textInputAction: TextInputAction.done,
                                  scrollPadding: EdgeInsets.only(
                                    bottom: bottomInset + 120,
                                  ),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                  decoration: fieldDecoration.copyWith(
                                    hintText: 'Optional',
                                  ),
                                  onFieldSubmitted: (_) {
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                  },
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const HomeworkFormSectionLabel(label: 'Fach & Fälligkeit'),
                    HomeworkDueSection(
                      selectedSubjectId: _selectedSubjectId,
                      selectedDay: _selectedDay,
                      onDayChanged: (day) => setState(() {
                        _selectedDay = day;
                        _dueNextLesson = false;
                      }),
                      onSubjectChanged: _onSubjectChanged,
                      dueNextLesson: _dueNextLesson,
                      onDueNextLessonChanged: (value) {
                        setState(() => _dueNextLesson = value);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xl),
                      child: HomeworkFormFooter(
                        busy: _saving,
                        submitEnabled: _canCreate,
                        submitLabel: 'Aufgabe speichern',
                        onSubmit: () {
                          AppHaptics.light();
                          _onCreate();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
