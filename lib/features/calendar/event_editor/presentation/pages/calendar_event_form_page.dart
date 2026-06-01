import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/providers/filter/calendar/calendar_filter_options_providers.dart';
import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/calendar_event_write_repository.dart';
import '../../domain/calendar_event_form_factory.dart';
import '../../domain/calendar_event_form_mode.dart';
import '../../domain/calendar_event_form_state.dart';
import '../../domain/calendar_event_save_scope.dart';
import '../../domain/calendar_series_edit_state.dart';
import '../providers/calendar_event_editor_providers.dart';
import '../providers/calendar_event_form_controller.dart';
import '../widgets/dialogs/event_save_scope_dialog.dart';
import '../widgets/event_form_modal_header.dart';
import '../../data/calendar_event_target_resolver.dart';
import '../widgets/sections/event_audience_section.dart';
import '../widgets/sections/event_basic_section.dart';
import '../widgets/sections/event_datetime_section.dart';
import '../widgets/sections/event_extra_section.dart';
import '../widgets/sections/event_recurrence_section.dart';
import '../widgets/sections/event_subject_section.dart';

class CalendarEventFormPage extends ConsumerStatefulWidget {
  const CalendarEventFormPage({
    super.key,
    required this.sourceEntry,
    this.mode = CalendarEventFormMode.edit,
  });

  final CalendarEntry sourceEntry;
  final CalendarEventFormMode mode;

  /// Bottom-Sheet mit App-Hintergrund und abgerundeten oberen Ecken.
  static Future<void> show(
    BuildContext context, {
    required CalendarEntry sourceEntry,
    CalendarEventFormMode mode = CalendarEventFormMode.edit,
  }) {
    return AppModalSheet.show<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final view = View.of(sheetContext);
        final screenHeight =
            view.physicalSize.height / view.devicePixelRatio;
        return SizedBox(
          height: screenHeight * 0.9,
          child: CalendarEventFormPage(
            sourceEntry: sourceEntry,
            mode: mode,
          ),
        );
      },
    );
  }

  @override
  ConsumerState<CalendarEventFormPage> createState() =>
      _CalendarEventFormPageState();
}

class _CalendarEventFormPageState extends ConsumerState<CalendarEventFormPage> {
  late CalendarEventFormState _formState;
  late CalendarEventFormState _initialFormState;
  late final TextEditingController _eventNameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _noteController;
  bool _saving = false;
  bool _loadingSeries = false;

  @override
  void initState() {
    super.initState();
    _formState = CalendarEventFormFactory.fromEntry(widget.sourceEntry);
    _initialFormState = _formState;
    _eventNameController = TextEditingController(text: _formState.eventName);
    _descriptionController = TextEditingController(text: _formState.description);
    _locationController = TextEditingController(text: _formState.location);
    _noteController = TextEditingController(text: _formState.note);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppHaptics.light();
      _loadSeriesMetadata();
    });
  }

  Future<void> _loadSeriesMetadata() async {
    final seriesId =
        CalendarEventTargetResolver.resolveSeriesId(widget.sourceEntry);
    if (seriesId == null) return;

    setState(() => _loadingSeries = true);
    try {
      final snapshot =
          await ref.read(calendarEventSeriesReaderProvider).read(seriesId);
      if (!mounted || snapshot == null) return;
      setState(() {
        _formState = _formState.copyWith(
          seriesEdit: snapshot.series,
          subjectId: snapshot.subjectId ?? _formState.subjectId,
        );
        _initialFormState = _formState;
      });
    } finally {
      if (mounted) setState(() => _loadingSeries = false);
    }
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _isDirty {
    return !_formStatesEqual(_snapshotFromControllers(), _initialFormState);
  }

  CalendarEventFormState _snapshotFromControllers() {
    return _formState.copyWith(
      eventName: _eventNameController.text,
      description: _descriptionController.text,
      location: _locationController.text,
      note: _noteController.text,
    );
  }

  void _applyFormState(CalendarEventFormState next) {
    setState(() => _formState = next);
  }

  CalendarEventFormController _controller() {
    return CalendarEventFormController(
      writeRepository: ref.read(calendarEventWriteRepositoryProvider),
      targetResolver: ref.read(calendarEventTargetResolverProvider),
    );
  }

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Änderungen verwerfen?'),
        content: const Text('Nicht gespeicherte Änderungen gehen verloren.'),
        actions: [
          TextButton(
            onPressed: () {
              AppHaptics.selection();
              Navigator.of(context).pop(false);
            },
            child: const Text('Weiter bearbeiten'),
          ),
          FilledButton(
            onPressed: () {
              AppHaptics.medium();
              Navigator.of(context).pop(true);
            },
            child: const Text('Verwerfen'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _onClose() async {
    final discard = await _confirmDiscard();
    if (discard && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _onSave() async {
    if (_saving) return;
    final snapshot = _snapshotFromControllers();
    final ctrl = _controller();
    final validation = await ctrl.validate(snapshot);
    if (!validation.isValid) {
      await AppHaptics.error();
      if (!mounted) return;
      showAppToast(
        context,
        validation.errorMessage!,
        kind: AppToastKind.error,
      );
      return;
    }

    CalendarEventSaveScope? scope;
    if (ctrl.needsSaveScopeDialog(widget.sourceEntry)) {
      if (!mounted) return;
      scope = await showEventSaveScopeDialog(context);
      if (scope == null || !mounted) return;
    }

    setState(() => _saving = true);
    try {
      await ctrl.save(
        sourceEntry: widget.sourceEntry,
        state: snapshot,
        scope: scope,
      );
      await AppHaptics.success();
      if (!mounted) return;
      showAppToast(context, 'Termin gespeichert.', kind: AppToastKind.success);
      Navigator.of(context).pop();
    } on CalendarEventWriteException catch (e) {
      await AppHaptics.error();
      if (!mounted) return;
      showAppToast(context, e.message, kind: AppToastKind.error);
    } catch (_) {
      await AppHaptics.error();
      if (!mounted) return;
      showAppToast(
        context,
        'Speichern fehlgeschlagen. Bitte erneut versuchen.',
        kind: AppToastKind.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classOptions =
        ref.watch(calendarClassFilterOptionsProvider).asData?.value ??
        const <String>[];

    final title = widget.mode == CalendarEventFormMode.edit
        ? 'Bearbeiten'
        : 'Termin erstellen';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _onClose();
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: AppModalSheetChrome(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                EventFormModalHeader(
                  title: title,
                  saving: _saving,
                  onClose: _onClose,
                  onSave: _onSave,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.l,
                      AppSpacing.m,
                      AppSpacing.l,
                      AppSpacing.xl,
                    ),
                    children: [
                      EventBasicSection(
                        state: _formState,
                        onChanged: _applyFormState,
                        eventNameController: _eventNameController,
                        descriptionController: _descriptionController,
                        locationController: _locationController,
                      ),
                      EventSubjectSection(
                        state: _formState,
                        onChanged: _applyFormState,
                      ),
                      const SizedBox(height: AppSpacing.m),
                      EventDatetimeSection(
                        state: _formState,
                        onChanged: _applyFormState,
                      ),
                      if (_formState.isRecurringEntry) ...[
                        const SizedBox(height: AppSpacing.m),
                        if (_loadingSeries)
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.m,
                            ),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else
                          EventRecurrenceSection(
                            state: _formState,
                            onChanged: _applyFormState,
                          ),
                      ],
                      const SizedBox(height: AppSpacing.m),
                      EventAudienceSection(
                        state: _formState,
                        onChanged: _applyFormState,
                        classOptions: classOptions,
                      ),
                      const SizedBox(height: AppSpacing.m),
                      EventExtraSection(
                        state: _formState,
                        onChanged: _applyFormState,
                        noteController: _noteController,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

bool _formStatesEqual(CalendarEventFormState a, CalendarEventFormState b) {
  return a.eventName == b.eventName &&
      a.type == b.type &&
      a.description == b.description &&
      a.location == b.location &&
      a.note == b.note &&
      a.startTime == b.startTime &&
      a.endTime == b.endTime &&
      a.choir == b.choir &&
      _listEquals(a.voices, b.voices) &&
      a.schoolTrack == b.schoolTrack &&
      a.className == b.className &&
      a.diet == b.diet &&
      a.subjectId == b.subjectId &&
      _seriesEditEquals(a.seriesEdit, b.seriesEdit);
}

bool _seriesEditEquals(
  CalendarSeriesEditState? a,
  CalendarSeriesEditState? b,
) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  return a.frequency == b.frequency &&
      a.interval == b.interval &&
      a.seriesStart == b.seriesStart &&
      a.seriesEnd == b.seriesEnd &&
      _setEquals(a.weekdays, b.weekdays);
}

bool _setEquals<T>(Set<T> a, Set<T> b) {
  if (a.length != b.length) return false;
  for (final item in a) {
    if (!b.contains(item)) return false;
  }
  return true;
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
