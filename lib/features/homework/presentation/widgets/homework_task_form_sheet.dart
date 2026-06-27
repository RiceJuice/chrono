import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:chronoapp/features/calendar/presentation/providers/filter/calendar/calendar_filtered_entries_providers.dart';
import 'package:chronoapp/features/homework/domain/homework_syntax_parser.dart';
import 'package:chronoapp/features/homework/domain/models/homework_fragment.dart';
import 'package:chronoapp/features/homework/domain/models/homework_task.dart';
import 'package:chronoapp/features/homework/domain/next_lesson_for_subject.dart';
import 'package:chronoapp/features/homework/presentation/providers/homework_due_providers.dart';
import 'package:chronoapp/features/homework/presentation/providers/homework_providers.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_due_section.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_form_shell.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_syntax_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeworkTaskFormSheet extends ConsumerStatefulWidget {
  const HomeworkTaskFormSheet({super.key});

  static Future<void> show(BuildContext context) {
    return AppModalSheet.show<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      sheetAnimationStyle: kAppModalSheetMotion,
      builder: (sheetContext) {
        return AppModalSheetChrome(
          constraints: appModalHomeworkFormSheetConstraints(sheetContext),
          child: const HomeworkTaskFormSheet(),
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
  final _descriptionController = TextEditingController();
  String? _homeworkValidationError;
  String? _selectedSubjectId;
  HomeworkDueMode _dueMode = HomeworkDueMode.none;
  DateTime _customDueDate = AppDateTime.todayLocal();
  bool _saving = false;
  List<HomeworkFragment> _committedFragments = const [];
  String _activeText = '';
  bool _autoSubjectApplied = false;

  DateTime get _lessonDate => AppDateTime.todayLocal();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyAutoSubject());
  }

  @override
  void dispose() {
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
      _selectedSubjectId = subjectId;
      if (subjectId == null || subjectId.isEmpty) {
        if (_dueMode == HomeworkDueMode.nextLesson) {
          _dueMode = HomeworkDueMode.none;
        }
      }
    });
  }

  void _onSyntaxChanged(List<HomeworkFragment> fragments, String activeText) {
    setState(() {
      _committedFragments = fragments;
      _activeText = activeText;
      if (fragments.isNotEmpty || activeText.trim().isNotEmpty) {
        _homeworkValidationError = null;
      }
    });
  }

  bool _hasHomeworkContent(HomeworkSyntaxParser parser) {
    return _resolveFragments(parser).isNotEmpty;
  }

  bool get _canCreate {
    if (_dueMode != HomeworkDueMode.nextLesson) return true;

    final subjectId = _selectedSubjectId?.trim();
    if (subjectId == null || subjectId.isEmpty) return false;

    final nextLesson = ref.read(nextLessonForSubjectProvider(subjectId));
    return nextLesson.maybeWhen(data: (lesson) => lesson != null, orElse: () => false);
  }

  ({DateTime? dueAt, HomeworkDueSource? dueSource}) _resolveDueFields() {
    return switch (_dueMode) {
      HomeworkDueMode.none => (dueAt: null, dueSource: null),
      HomeworkDueMode.customDate => (
          dueAt: homeworkDueAtEndOfLocalDay(_customDueDate),
          dueSource: HomeworkDueSource.customDate,
        ),
      HomeworkDueMode.nextLesson => _resolveNextLessonDue(),
    };
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

  List<HomeworkFragment> _resolveFragments(HomeworkSyntaxParser parser) {
    return homeworkFragmentsFromField(
      parser: parser,
      committedFragments: _committedFragments,
      activeText: _activeText,
    );
  }

  Future<void> _onCreate() async {
    if (_saving || !_canCreate) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final suggestions = ref.read(homeworkSyntaxSuggestionsProvider).asData?.value ?? const [];
    final parser = HomeworkSyntaxParser(suggestions: suggestions);
    final fragments = _resolveFragments(parser);

    if (!_hasHomeworkContent(parser)) {
      setState(() => _homeworkValidationError = 'Bitte eine Hausaufgabe eingeben.');
      return;
    }

    final dueFields = _resolveDueFields();

    setState(() => _saving = true);
    try {
      final profile = ref.read(effectiveHomeworkProfileProvider);
      final profileId = ref.read(effectiveHomeworkProfileIdProvider);
      String? contributionId;

      if (profile != null &&
          profileId != null &&
          profile.className != null &&
          profile.className!.trim().isNotEmpty &&
          _selectedSubjectId != null &&
          fragments.isNotEmpty) {
        final contributionRepo = ref.read(homeworkContributionRepositoryProvider);
        final classContributions =
            ref.read(homeworkClassContributionsProvider(_lessonDate)).asData?.value ??
                const [];

        contributionId = await contributionRepo.upsertContribution(
          profileId: profileId,
          className: profile.className!.trim(),
          schooltrack: profile.schoolTrack,
          subjectId: _selectedSubjectId!,
          lessonDate: _lessonDate,
          localFragments: fragments,
          classContributions: classContributions,
        );
      }

      await ref.read(homeworkTasksProvider.notifier).addTask(
            fragments: fragments,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            subjectId: _selectedSubjectId,
            dueAt: dueFields.dueAt,
            dueSource: dueFields.dueSource,
            contributionId: contributionId,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _onAddCustomSuggestion(String label, String shorthand) async {
    final profileId = ref.read(effectiveHomeworkProfileIdProvider);
    if (profileId == null) return;

    final repository = ref.read(homeworkSyntaxSuggestionRepositoryProvider);
    await repository.createUserSuggestion(
      profileId: profileId,
      label: label,
      shorthand: shorthand,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final suggestionsAsync = ref.watch(homeworkSyntaxSuggestionsProvider);
    final suggestions = suggestionsAsync.asData?.value ?? const [];
    final parser = HomeworkSyntaxParser(suggestions: suggestions);

    final fieldDecoration = InputDecoration(
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      filled: false,
      isDense: true,
      contentPadding: EdgeInsets.zero,
      hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.s,
          AppSpacing.xl,
          AppSpacing.m + bottomInset,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              const HomeworkFormHeader(title: 'Neue Aufgabe'),
              const SizedBox(height: AppSpacing.m),
              HomeworkFormGroup(
                children: [
                  HomeworkFormField(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        HomeworkSyntaxField(
                          parser: parser,
                          suggestions: suggestions,
                          committedFragments: _committedFragments,
                          activeText: _activeText,
                          onChanged: _onSyntaxChanged,
                          onAddCustomSuggestion: _onAddCustomSuggestion,
                        ),
                        if (_homeworkValidationError != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _homeworkValidationError!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.error,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  HomeworkFormField(
                    child: TextFormField(
                      controller: _descriptionController,
                      maxLines: 2,
                      textInputAction: TextInputAction.done,
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: fieldDecoration.copyWith(
                        hintText: 'Beschreibung (optional)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.m),
              HomeworkDueSection(
                selectedSubjectId: _selectedSubjectId,
                onSubjectChanged: _onSubjectChanged,
                mode: _dueMode,
                onModeChanged: (mode) => setState(() => _dueMode = mode),
                customDueDate: _customDueDate,
                onCustomDueDateChanged: (date) {
                  setState(() => _customDueDate = date);
                },
              ),
              const SizedBox(height: AppSpacing.l),
              HomeworkFormFooter(
                busy: _saving,
                submitEnabled: _canCreate,
                submitLabel: 'Aufgabe erstellen',
                onCancel: () {
                  AppHaptics.selection();
                  Navigator.of(context).pop();
                },
                onSubmit: () {
                  AppHaptics.light();
                  _onCreate();
                },
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
