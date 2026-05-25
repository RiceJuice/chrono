import '../../data/calendar_event_target_resolver.dart';
import '../../data/calendar_event_write_repository.dart';
import '../../domain/calendar_event_edit_target.dart';
import '../../domain/calendar_event_form_state.dart';
import '../../domain/calendar_event_form_validator.dart';
import '../../domain/calendar_event_save_scope.dart';
import '../../../domain/models/calendar_entry.dart';

class CalendarEventFormController {
  CalendarEventFormController({
    required CalendarEventWriteRepository writeRepository,
    required CalendarEventTargetResolver targetResolver,
  })  : _writeRepository = writeRepository,
        _targetResolver = targetResolver;

  final CalendarEventWriteRepository _writeRepository;
  final CalendarEventTargetResolver _targetResolver;

  CalendarEventEditTarget? _cachedTarget;

  bool needsSaveScopeDialog(CalendarEntry entry) {
    return CalendarEventTargetResolver.needsSaveScopeDialog(entry);
  }

  Future<CalendarEventFormValidationResult> validate(CalendarEventFormState state) {
    return Future.value(
      CalendarEventFormValidator.validate(
        eventName: state.eventName,
        startTime: state.startTime,
        endTime: state.endTime,
        seriesEdit: state.seriesEdit,
      ),
    );
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
