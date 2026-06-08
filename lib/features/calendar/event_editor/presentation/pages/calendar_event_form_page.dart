import 'dart:async';
import 'dart:io';

import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/core/widgets/app_dialog.dart';
import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/providers/filter/calendar/calendar_filter_options_providers.dart';
import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/calendar_event_write_repository.dart';
import '../../domain/calendar_event_form_factory.dart';
import '../../domain/calendar_event_change_summary.dart';
import '../../domain/calendar_event_pending_attachment.dart';
import '../../domain/calendar_event_form_mode.dart';
import '../../domain/calendar_event_form_state.dart';
import '../../domain/calendar_event_save_scope.dart';
import '../../domain/calendar_series_edit_state.dart';
import '../providers/calendar_event_editor_providers.dart';
import '../providers/calendar_event_form_controller.dart';
import '../providers/is_admin_provider.dart';
import '../../data/calendar_event_source_upload_service.dart';
import '../../data/event_broadcast_service.dart';
import '../widgets/dialogs/event_broadcast_dialog.dart';
import '../widgets/dialogs/event_delete_scope_dialog.dart';
import '../widgets/dialogs/event_image_attach_sheet.dart';
import '../widgets/dialogs/event_save_scope_dialog.dart';
import '../widgets/event_attach_source_panel.dart';
import '../widgets/event_attach_source_reveal.dart';
import '../widgets/event_form_attachment_focus_view.dart';
import '../widgets/event_form_modal_header.dart';
import '../../data/calendar_event_target_resolver.dart';
import '../widgets/sections/event_audience_section.dart';
import '../widgets/sections/event_basic_section.dart';
import '../widgets/sections/event_datetime_section.dart';
import '../widgets/sections/event_extra_section.dart';
import '../widgets/sections/event_recurrence_section.dart';
import '../utils/event_attachment_picker.dart';
import '../widgets/sections/event_subject_section.dart';

class CalendarEventFormPage extends ConsumerStatefulWidget {
  const CalendarEventFormPage({
    super.key,
    this.sourceEntry,
    this.mode = CalendarEventFormMode.edit,
    this.initialDay,
    this.initialFormState,
    this.initialPendingAttachments,
  }) : assert(
          mode == CalendarEventFormMode.create || sourceEntry != null,
          'sourceEntry is required in edit mode',
        );

  final CalendarEntry? sourceEntry;
  final CalendarEventFormMode mode;

  /// Kalendertag für Standard-Uhrzeiten beim Erstellen.
  final DateTime? initialDay;

  /// Wiederherstellung nach iOS-Dateiauswahl (Sheet wurde kurz geschlossen).
  final CalendarEventFormState? initialFormState;
  final List<CalendarEventPendingAttachment>? initialPendingAttachments;

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
    CalendarEventFormState? initialFormState,
    List<CalendarEventPendingAttachment>? initialPendingAttachments,
  }) {
    return AppModalSheet.show<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (sheetContext) {
        return CalendarEventFormPage(
          mode: CalendarEventFormMode.create,
          initialDay: initialDay,
          initialFormState: initialFormState,
          initialPendingAttachments: initialPendingAttachments,
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
        ? (widget.initialFormState ??
            CalendarEventFormFactory.forCreate(
              day: widget.initialDay ?? DateTime.now(),
            ))
        : CalendarEventFormFactory.fromEntry(widget.sourceEntry!);
    _initialFormState = _formState;
    _eventNameController = TextEditingController(text: _formState.eventName);
    _descriptionController =
        TextEditingController(text: _formState.description);
    _locationController = TextEditingController(text: _formState.location);
    _noteController = TextEditingController(text: _formState.note);
    final restored = widget.initialPendingAttachments;
    if (restored != null && restored.isNotEmpty) {
      _pendingAttachments
        ..clear()
        ..addAll(restored);
    }
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
    return showAppConfirmDialog(
      context: context,
      title: 'Änderungen verwerfen?',
      message:
          'Deine Anpassungen an diesem Termin wurden noch nicht gespeichert.',
      cancelLabel: 'Weiter bearbeiten',
      confirmLabel: 'Verwerfen',
    );
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

    return showAppConfirmDialog(
      context: context,
      title: 'Termin löschen?',
      message: label.isNotEmpty
          ? '„$label“ wird unwiderruflich entfernt.'
          : 'Dieser Termin wird unwiderruflich entfernt.',
      confirmLabel: 'Löschen',
      confirmRole: AppDialogActionRole.destructive,
    );
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

  Future<CalendarEventPendingAttachment?> _attachmentFromPickedFile(
    EventPickedFile picked, {
    int idSuffix = 0,
  }) async {
    final file = picked.file;
    final displayName = picked.displayName;
    final isImage = EventAttachmentPicker.isImagePath(file.path);
    final isPdf = EventAttachmentPicker.isPdfPath(file.path);
    final id = '${DateTime.now().microsecondsSinceEpoch}_$idSuffix';

    final persisted = await EventAttachmentPicker.persistPickedFile(
      file,
      displayName: displayName,
    );
    return CalendarEventPendingAttachment(
      id: id,
      localPath: persisted.path,
      displayName: EventAttachmentPicker.displayNameForFile(persisted.path),
      isImage: isImage,
      isPdf: isPdf,
    );
  }

  Future<List<CalendarEventPendingAttachment>> _attachmentsFromPickedFiles(
    List<EventPickedFile> pickedFiles,
  ) async {
    if (pickedFiles.isEmpty) return const [];

    final attachments = <CalendarEventPendingAttachment>[];
    for (var i = 0; i < pickedFiles.length; i++) {
      final attachment = await _attachmentFromPickedFile(
        pickedFiles[i],
        idSuffix: i,
      );
      if (attachment != null) {
        attachments.add(attachment);
      }
    }
    return attachments;
  }

  Future<void> _onAttachSourceSelected(EventImageAttachSource source) async {
    if (_saving || _attachingMedia) return;

    setState(() => _attachMenuOpen = false);

    if (_isCreateMode &&
        source == EventImageAttachSource.file &&
        EventAttachmentPicker.mustDismissParentSheetBeforePick) {
      await _pickDocumentWithIosSheetDismissed();
      return;
    }

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
      final picked = await _pickFilesForSource(source);
      if (picked.isEmpty || !mounted) return;

      final attachments = await _attachmentsFromPickedFiles(picked);
      if (attachments.isEmpty || !mounted) return;

      setState(() {
        _attachMenuOpen = false;
        _pendingAttachments.addAll(attachments);
      });
      await AppHaptics.success();
      if (!mounted) return;
      _logUpload(
        'picked ${attachments.length} file(s): '
        '${attachments.map((a) => a.localPath).join(', ')}',
      );
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

  /// iOS: Modal-Sheet schließen, damit der UIDocumentPicker Touch-Events erhält.
  Future<void> _pickDocumentWithIosSheetDismissed() async {
    final hostContext = Navigator.of(context, rootNavigator: true).context;
    final initialDay = widget.initialDay ?? DateTime.now();
    final formSnapshot = _snapshotFromControllers();
    final pendingSnapshot =
        List<CalendarEventPendingAttachment>.from(_pendingAttachments);

    Navigator.of(context, rootNavigator: true).pop();

    await Future<void>.delayed(EventAttachmentPicker.iosSheetDismissDelay);
    if (!hostContext.mounted) return;

    Future<void> reopenForm({
      List<CalendarEventPendingAttachment>? pending,
    }) {
      return CalendarEventFormPage.showCreate(
        hostContext,
        initialDay: initialDay,
        initialFormState: formSnapshot,
        initialPendingAttachments: pending ?? pendingSnapshot,
      );
    }

    try {
      final picked = await EventAttachmentPicker.pickDocuments();
      if (picked.isEmpty) {
        await reopenForm();
        return;
      }

      final attachments = await _attachmentsFromPickedFiles(picked);
      if (attachments.isEmpty) {
        await reopenForm();
        return;
      }
      await AppHaptics.success();
      if (!hostContext.mounted) return;
      await reopenForm(
        pending: [...pendingSnapshot, ...attachments],
      );
      _logUpload(
        'picked ${attachments.length} file(s) (ios sheet dismiss)',
      );
    } catch (e, stack) {
      await AppHaptics.error();
      _logUpload('pick failed (ios sheet dismiss): $e\n$stack');
      if (hostContext.mounted) {
        showAppToast(
          hostContext,
          'Auswahl fehlgeschlagen. Bitte erneut versuchen.',
          kind: AppToastKind.error,
        );
        await reopenForm();
      }
    }
  }

  Future<List<EventPickedFile>> _pickFilesForSource(
    EventImageAttachSource source,
  ) async {
    try {
      switch (source) {
        case EventImageAttachSource.camera:
          final photo = await _imagePicker.pickImage(
            source: ImageSource.camera,
            imageQuality: 90,
            requestFullMetadata: true,
          );
          final picked = EventAttachmentPicker.fromXFile(photo);
          return picked == null ? const [] : [picked];
        case EventImageAttachSource.gallery:
          return EventAttachmentPicker.pickGalleryImages(_imagePicker);
        case EventImageAttachSource.file:
          return EventAttachmentPicker.pickDocuments();
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
      return const [];
    }
  }

  void _removePendingAttachment(String id) {
    setState(() {
      _pendingAttachments.removeWhere((a) => a.id == id);
    });
    AppHaptics.selection();
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
      final count = localFiles.length;
      showAppToast(
        context,
        count == 1
            ? 'Datei hochgeladen — wird verarbeitet.'
            : '$count Dateien hochgeladen — werden verarbeitet.',
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
      final beforeSave = _initialFormState;
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

      final changeSummary = CalendarEventChangeSummary.fromStates(
        before: beforeSave,
        after: snapshot,
      );
      if (changeSummary.hasChanges && mounted) {
        final broadcast = await showEventBroadcastDialog(
          context,
          summary: changeSummary,
        );
        if (broadcast == true && mounted) {
          try {
            await ref.read(eventBroadcastServiceProvider).notifyChange(
                  eventId: sourceEntry.id,
                  summary: changeSummary,
                );
          } on EventBroadcastException catch (e) {
            if (mounted) {
              showAppToast(
                context,
                e.message,
                kind: AppToastKind.error,
              );
            }
          } catch (e, stack) {
            debugPrint('[EventForm] broadcast failed: $e\n$stack');
            if (mounted) {
              showAppToast(
                context,
                'Benachrichtigung fehlgeschlagen.',
                kind: AppToastKind.error,
              );
            }
          }
        }
      }

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

    final header = EventFormModalHeader(
      title: title,
      saving: _saving,
      titleAlign: _isCreateMode ? TextAlign.start : TextAlign.center,
      onAttachMedia:
          _isCreateMode && !_saving ? _toggleAttachMenu : null,
      attachingMedia: _attachingMedia,
      onClose: _onClose,
      onSave: _onHeaderSave,
      saveTooltip: _attachmentFocusMode ? 'Hochladen' : 'Speichern',
      contrastImagePath: _attachmentFocusMode && _pendingAttachments.isNotEmpty
          ? _pendingAttachments.first.localPath
          : null,
    );

    final formBody = _attachmentFocusMode
        ? Column(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    EventFormAttachmentFocusView(
                      attachments: _pendingAttachments,
                      uploading: _saving,
                      onRemove: _saving ? null : _removePendingAttachment,
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: header,
                    ),
                    if (_attachMenuOpen)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Material(
                          color: Theme.of(context).colorScheme.surface,
                          elevation: 2,
                          child: EventAttachSourceReveal(
                            visible: true,
                            onSelected: _onAttachSourceSelected,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          )
        : Column(
            children: [
              header,
              EventAttachSourceReveal(
                visible: _isCreateMode && _attachMenuOpen,
                onSelected: _onAttachSourceSelected,
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
          constraints: appModalEventFormSheetConstraints(context),
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
