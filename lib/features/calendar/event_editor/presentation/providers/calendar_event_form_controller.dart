import 'dart:io';

import '../../data/calendar_event_source_upload_service.dart';
import '../../data/calendar_event_target_resolver.dart';
import '../../data/calendar_event_write_repository.dart';
import '../../domain/calendar_event_edit_target.dart';
import '../../domain/calendar_event_form_mode.dart';
import '../../domain/calendar_event_form_state.dart';
import '../../domain/calendar_event_form_validator.dart';
import '../../domain/calendar_event_save_scope.dart';
import '../../../domain/models/calendar_entry.dart';

class CalendarEventFormController {
  CalendarEventFormController({
    required CalendarEventWriteRepository writeRepository,
    required CalendarEventTargetResolver targetResolver,
    CalendarEventSourceUploadService? sourceUploadService,
  })  : _writeRepository = writeRepository,
        _targetResolver = targetResolver,
        _sourceUploadService = sourceUploadService;

  final CalendarEventWriteRepository _writeRepository;
  final CalendarEventTargetResolver _targetResolver;
  final CalendarEventSourceUploadService? _sourceUploadService;

  CalendarEventEditTarget? _cachedTarget;

  bool needsSaveScopeDialog(CalendarEntry entry) {
    return CalendarEventTargetResolver.needsSaveScopeDialog(entry);
  }

  Future<CalendarEventFormValidationResult> validate(
    CalendarEventFormState state, {
    CalendarEventFormMode mode = CalendarEventFormMode.edit,
  }) {
    return Future.value(
      CalendarEventFormValidator.validate(
        eventName: state.eventName,
        startTime: state.startTime,
        endTime: state.endTime,
        seriesEdit: state.seriesEdit,
        mode: mode,
        choir: state.choir,
        voices: state.voices,
        schoolTrack: state.schoolTrack,
        className: state.className,
      ),
    );
  }

  Future<String> create({required CalendarEventFormState state}) async {
    return _writeRepository.createStandalone(state: state);
  }

  Future<List<String>> uploadSourceFiles(List<File> files) async {
    if (files.isEmpty) return const <String>[];

    final uploader = _sourceUploadService;
    if (uploader == null) {
      throw CalendarEventSourceUploadException(
        'Datei konnte nicht hochgeladen werden.',
      );
    }

    final paths = <String>[];
    for (final file in files) {
      paths.add(await uploader.uploadSourceFile(file: file));
    }
    return paths;
  }

  Future<void> delete({
    required CalendarEntry sourceEntry,
    CalendarEventSaveScope? scope,
  }) async {
    _cachedTarget ??= await _targetResolver.resolve(sourceEntry);
    final target = _cachedTarget!;

    if (target.isRecurring && scope == null) {
      throw CalendarEventWriteException(
        'Bitte wählen, ob nur dieser Termin oder die ganze Serie gelöscht wird.',
      );
    }

    await _writeRepository.delete(target: target, scope: scope);
  }

  Future<void> save({
    required CalendarEntry sourceEntry,
    required CalendarEventFormState state,
    CalendarEventSaveScope? scope,
  }) async {
    _cachedTarget ??= await _targetResolver.resolve(sourceEntry);
    final target = _cachedTarget!;

    if (target.isRecurring && scope == null) {
      throw CalendarEventWriteException(
        'Bitte wählen, ob nur dieser Termin oder die ganze Serie gespeichert wird.',
      );
    }

    if (scope == CalendarEventSaveScope.entireSeries && state.seriesEdit == null) {
      throw CalendarEventWriteException(
        'Serien-Daten konnten nicht geladen werden. Bitte erneut öffnen.',
      );
    }

    await _writeRepository.save(
      target: target,
      state: state,
      scope: scope,
    );
  }
}
