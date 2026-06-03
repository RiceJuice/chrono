import 'dart:async';
import 'dart:io';

import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/providers/filter/calendar/calendar_filter_options_providers.dart';
import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/calendar_event_write_repository.dart';
import '../../domain/calendar_event_form_factory.dart';
import '../../domain/calendar_event_pending_attachment.dart';
import '../../domain/calendar_event_form_mode.dart';
import '../../domain/calendar_event_form_state.dart';
import '../../domain/calendar_event_save_scope.dart';
import '../../domain/calendar_series_edit_state.dart';
import '../providers/calendar_event_editor_providers.dart';
import '../providers/calendar_event_form_controller.dart';
import '../providers/is_admin_provider.dart';
import '../../data/calendar_event_source_upload_service.dart';
import '../widgets/dialogs/event_delete_scope_dialog.dart';
import '../widgets/dialogs/event_image_attach_sheet.dart';
import '../widgets/dialogs/event_save_scope_dialog.dart';
import '../widgets/event_attach_source_panel.dart';
import '../widgets/event_form_attachment_focus_view.dart';
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
    this.sourceEntry,
    this.mode = CalendarEventFormMode.edit,
    this.initialDay,
  }) : assert(
          mode == CalendarEventFormMode.create || sourceEntry != null,
          'sourceEntry is required in edit mode',
        );

  final CalendarEntry? sourceEntry;
  final CalendarEventFormMode mode;

  /// Kalendertag für Standard-Uhrzeiten beim Erstellen.
  final DateTime? initialDay;

  /// Bottom-Sheet mit App-Hintergrund und abgerundeten oberen Ecken.
  static Future<void> show(
    BuildContext context, {
    required CalendarEntry sourceEntry,
    CalendarEventFormMode mode = CalendarEventFormMode.edit,
  }) {
    return AppModalSheet.show<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (sheetContext) {
        return CalendarEventFormPage(
          sourceEntry: sourceEntry,
          mode: mode,
        );
      },
    );
  }

  /// Erstellen-Modal aus der Hauptnavigation (kein eigener Tab).
  static Future<void> showCreate(
    BuildContext context, {
    required DateTime initialDay,
  }) {
    return AppModalSheet.show<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (sheetContext) {
        return CalendarEventFormPage(
          mode: CalendarEventFormMode.create,
          initialDay: initialDay,
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
  bool _attachingMedia = false;
  bool _attachMenuOpen = false;
  final List<CalendarEventPendingAttachment> _pendingAttachments = [];
  final ImagePicker _imagePicker = ImagePicker();

  bool get _isCreateMode => widget.mode == CalendarEventFormMode.create;

  @override
  void initState() {
    super.initState();
    _resetFormState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppHaptics.light();
      if (!_isCreateMode) {
        _loadSeriesMetadata();
      }
    });
  }

  void _resetFormState() {
    _formState = _isCreateMode
        ? CalendarEventFormFactory.forCreate(
            day: widget.initialDay ?? DateTime.now(),
          )
        : CalendarEventFormFactory.fromEntry(widget.sourceEntry!);
    _initialFormState = _formState;
    _eventNameController = TextEditingController(text: _formState.eventName);
    _descriptionController =
        TextEditingController(text: _formState.description);
    _locationController = TextEditingController(text: _formState.location);
    _noteController = TextEditingController(text: _formState.note);
  }

  Future<void> _loadSeriesMetadata() async {
    final entry = widget.sourceEntry;
    if (entry == null) return;
    final seriesId = CalendarEventTargetResolver.resolveSeriesId(entry);
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
    return _pendingAttachments.isNotEmpty ||
        !_formStatesEqual(_snapshotFromControllers(), _initialFormState);
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
      sourceUploadService: ref.read(calendarEventSourceUploadServiceProvider),
    );
  }

  void _logUpload(String message) {
    debugPrint('[EventSourceUpload] $message');
  }

  Future<void> _onHeaderSave() async {
    _logUpload(
      'header save tapped focus=$_attachmentFocusMode saving=$_saving',
    );
    if (_attachmentFocusMode) {
      await _onConfirmSourceUpload();
    } else {
      await _onSave();
    }
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

  Future<bool> _confirmDelete() async {
    final name = _eventNameController.text.trim();
    final fallback = widget.sourceEntry?.eventName.trim() ?? '';
    final label = name.isNotEmpty ? name : fallback;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('Termin löschen?'),
          content: Text(
            label.isNotEmpty
                ? '„$label“ wird dauerhaft entfernt. Das lässt sich nicht rückgängig machen.'
                : 'Dieser Termin wird dauerhaft entfernt. Das lässt sich nicht rückgängig machen.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                AppHaptics.selection();
                Navigator.of(context).pop(false);
              },
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              onPressed: () {
                AppHaptics.medium();
                Navigator.of(context).pop(true);
              },
              child: const Text('Löschen'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _onDelete() async {
    if (_saving || _isCreateMode || !ref.read(isAdminProvider)) return;

    final confirmed = await _confirmDelete();
    if (!confirmed || !mounted) return;

    final sourceEntry = widget.sourceEntry!;
    final ctrl = _controller();

    CalendarEventSaveScope? scope;
    if (ctrl.needsSaveScopeDialog(sourceEntry)) {
      scope = await showEventDeleteScopeDialog(context);
      if (scope == null || !mounted) return;
    }

    setState(() => _saving = true);
    try {
      await ctrl.delete(sourceEntry: sourceEntry, scope: scope);
      await AppHaptics.success();
      if (!mounted) return;
      showAppToast(context, 'Termin gelöscht.', kind: AppToastKind.success);
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
        'Löschen fehlgeschlagen. Bitte erneut versuchen.',
        kind: AppToastKind.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toggleAttachMenu() {
    if (_saving || _attachingMedia) return;
    setState(() => _attachMenuOpen = !_attachMenuOpen);
  }

  Future<void> _onAttachSourceSelected(EventImageAttachSource source) async {
    if (_saving || _attachingMedia) return;

    setState(() => _attachMenuOpen = false);

    if (source == EventImageAttachSource.camera &&
        EventAttachSourcePanel.isIosSimulator) {
      if (!mounted) return;
      showAppToast(
        context,
        'Die Kamera ist im Simulator nicht verfügbar. Bitte ein echtes iPhone nutzen.',
        kind: AppToastKind.error,
      );
      return;
    }

    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    setState(() => _attachingMedia = true);
    try {
      final file = await _pickFileForSource(source);
      if (file == null || !mounted) return;

      final persisted = await _persistPickedFile(file);
      if (!mounted) return;

      final path = persisted.path;
      final name = _displayNameForFile(path);
      setState(() {
        _attachMenuOpen = false;
        _pendingAttachments.add(
          CalendarEventPendingAttachment(
            id: '${DateTime.now().microsecondsSinceEpoch}',
            localPath: path,
            displayName: name,
            isImage: _isImagePath(path),
            isPdf: _isPdfPath(path),
          ),
        );
      });
      final fileSize = await persisted.length();
      await AppHaptics.success();
      if (!mounted) return;
      _logUpload('picked file path=$path size=$fileSize');
    } catch (e, stack) {
      await AppHaptics.error();
      if (!mounted) return;
      _logUpload('pick failed: $e\n$stack');
      showAppToast(
        context,
        'Auswahl fehlgeschlagen. Bitte erneut versuchen.',
        kind: AppToastKind.error,
      );
    } finally {
      if (mounted) setState(() => _attachingMedia = false);
    }
  }

  bool get _attachmentFocusMode =>
      _isCreateMode && _pendingAttachments.isNotEmpty;

  static bool _isImagePath(String path) {
    final ext = path.split('.').last.toLowerCase();
    return <String>{
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'heic',
      'heif',
    }.contains(ext);
  }

  static bool _isPdfPath(String path) {
    return path.split('.').last.toLowerCase() == 'pdf';
  }

  static String _displayNameForFile(String path) {
    final parts = path.split(RegExp(r'[/\\]'));
    return parts.isNotEmpty ? parts.last : path;
  }

  Future<File?> _pickFileForSource(EventImageAttachSource source) async {
    try {
      switch (source) {
        case EventImageAttachSource.camera:
          final photo = await _imagePicker.pickImage(
            source: ImageSource.camera,
            imageQuality: 85,
            requestFullMetadata: false,
          );
          return _fileFromXFile(photo);
        case EventImageAttachSource.gallery:
          final image = await _imagePicker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 85,
            requestFullMetadata: false,
          );
          return _fileFromXFile(image);
        case EventImageAttachSource.file:
          final result = await FilePicker.platform.pickFiles(
            withData: false,
            allowMultiple: false,
          );
          if (result == null || result.files.isEmpty) return null;
          final path = result.files.single.path;
          if (path == null || path.isEmpty) return null;
          return File(path);
      }
    } catch (e, stack) {
      debugPrint('[EventAttach] picker failed: $e\n$stack');
      if (mounted) {
        showAppToast(
          context,
          'Auswahl fehlgeschlagen. Bitte erneut versuchen.',
          kind: AppToastKind.error,
        );
      }
      return null;
    }
  }

  File? _fileFromXFile(XFile? file) {
    if (file == null) return null;
    final path = file.path;
    if (path.isEmpty) return null;
    return File(path);
  }

  void _removePendingAttachment(String id) {
    setState(() {
      _pendingAttachments.removeWhere((a) => a.id == id);
    });
    AppHaptics.selection();
  }

  /// Kopiert Picker-Dateien ins App-Temp — iOS löscht sonst Pfade vor dem Upload.
  Future<File> _persistPickedFile(File source) async {
    final dir = await getTemporaryDirectory();
    final ext = p.extension(source.path);
    final destPath = p.join(
      dir.path,
      'chrono_source_${DateTime.now().microsecondsSinceEpoch}$ext',
    );
    final dest = File(destPath);
    await dest.writeAsBytes(await source.readAsBytes(), flush: true);
    return dest;
  }

  Future<void> _onConfirmSourceUpload() async {
    if (_saving) {
      _logUpload('confirm skipped: already saving');
      return;
    }
    if (!_attachmentFocusMode) {
      _logUpload('confirm skipped: not in focus mode');
      return;
    }

    final localFiles = _pendingAttachments
        .map((a) => File(a.localPath))
        .toList(growable: false);
    if (localFiles.isEmpty) {
      _logUpload('confirm skipped: no pending files');
      return;
    }

    final auth = Supabase.instance.client.auth;
    _logUpload(
      'confirm start count=${localFiles.length} '
      'userId=${auth.currentUser?.id} '
      'hasSession=${auth.currentSession != null}',
    );

    setState(() => _saving = true);
    try {
      final paths = await _controller().uploadSourceFiles(localFiles);
      await AppHaptics.success();
      if (!mounted) return;
      _logUpload('confirm done paths=$paths — closing modal');
      showAppToast(
        context,
        'Datei hochgeladen — wird verarbeitet.',
        kind: AppToastKind.success,
      );
      Navigator.of(context, rootNavigator: true).pop();
    } on CalendarEventSourceUploadException catch (e) {
      await AppHaptics.error();
      if (!mounted) return;
      _logUpload('confirm error: $e');
      showAppToast(context, e.message, kind: AppToastKind.error);
    } catch (e, stack) {
      await AppHaptics.error();
      if (!mounted) return;
      _logUpload('confirm failed: $e\n$stack');
      showAppToast(
        context,
        'Upload fehlgeschlagen. Bitte erneut versuchen.',
        kind: AppToastKind.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _onSave() async {
    if (_saving) return;
    final snapshot = _snapshotFromControllers();
    final ctrl = _controller();
    final validation = await ctrl.validate(
      snapshot,
      mode: widget.mode,
    );
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

    setState(() => _saving = true);
    try {
      if (_isCreateMode) {
        await ctrl.create(state: snapshot);
        await AppHaptics.success();
        if (!mounted) return;
        showAppToast(
          context,
          'Termin erstellt.',
          kind: AppToastKind.success,
        );
        Navigator.of(context).pop();
        return;
      }

      final sourceEntry = widget.sourceEntry!;
      CalendarEventSaveScope? scope;
      if (ctrl.needsSaveScopeDialog(sourceEntry)) {
        if (!mounted) return;
        scope = await showEventSaveScopeDialog(context);
        if (scope == null || !mounted) return;
      }

      await ctrl.save(
        sourceEntry: sourceEntry,
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
    } catch (e, stack) {
      await AppHaptics.error();
      if (!mounted) return;
      debugPrint('[EventForm] save failed: $e\n$stack');
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
    final isAdmin = ref.watch(isAdminProvider);

    final title = widget.mode == CalendarEventFormMode.edit
        ? 'Bearbeiten'
        : _attachmentFocusMode
            ? 'Anhang'
            : 'Termin erstellen';

    final formBody = Column(
      children: [
        EventFormModalHeader(
          title: title,
          saving: _saving,
          titleAlign: _isCreateMode ? TextAlign.start : TextAlign.center,
          onAttachMedia:
              _isCreateMode && !_attachmentFocusMode ? _toggleAttachMenu : null,
          attachingMedia: _attachingMedia,
          onClose: _onClose,
          onSave: _onHeaderSave,
          saveTooltip: _attachmentFocusMode ? 'Hochladen' : 'Speichern',
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _isCreateMode && _attachMenuOpen && !_attachmentFocusMode
              ? EventAttachSourcePanel(onSelected: _onAttachSourceSelected)
              : const SizedBox.shrink(),
        ),
        if (_attachmentFocusMode)
          Expanded(
            child: EventFormAttachmentFocusView(
              attachments: _pendingAttachments,
              uploading: _saving,
              onRemove: _saving ? null : _removePendingAttachment,
            ),
          )
        else
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
                        showRequiredHints: _isCreateMode,
                      ),
                      EventSubjectSection(
                        state: _formState,
                        onChanged: _applyFormState,
                      ),
                      const SizedBox(height: AppSpacing.m),
                      EventDatetimeSection(
                        state: _formState,
                        onChanged: _applyFormState,
                        showRequiredHint: _isCreateMode,
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
                        showRequiredHint: _isCreateMode,
                      ),
                      const SizedBox(height: AppSpacing.m),
                      EventExtraSection(
                        state: _formState,
                        onChanged: _applyFormState,
                        noteController: _noteController,
                      ),
                      if (!_isCreateMode && isAdmin) ...[
                        const SizedBox(height: AppSpacing.xl),
                        Center(
                          child: TextButton.icon(
                            onPressed: _saving ? null : _onDelete,
                            icon: Icon(
                              Icons.delete_outline,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            label: Text(
                              'Termin löschen',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
              ],
            ),
          ),
      ],
    );

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
          constraints: appModalSheetHeightConstraints(context),
          child: SafeArea(
            top: false,
            bottom: false,
            child: formBody,
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
      _listEquals(a.imagePaths, b.imagePaths) &&
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
