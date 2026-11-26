import 'package:chronoapp/features/calendar/domain/models/calendar_entry_display_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hides import provenance while preserving event details', () {
    expect(
      calendarEntryDisplayText(
        'Konzert in München\nQuelle: Jahresplan.pdf\nImport: batch-v1\n'
        'Original: München\nEndzeit in der Quelle nicht angegeben.\n'
        'Unbestätigter Termin.',
      ),
      'Konzert in München\nEndzeit nicht angegeben.\nUnbestätigter Termin.',
    );
  });
  test('source-only descriptions leave no visible text', () {
    expect(calendarEntryDisplayText('Quelle: Plan.pdf\nOriginal: Probe'), '');
  });
  test('hides technical midnight explanation and keeps missing-time hint', () {
    expect(
      calendarEntryDisplayText(
        'Quelle: Plan.pdf\n'
        'Uhrzeit in der Quelle nicht angegeben. 00:00 ist ausschließlich ein technischer Datumsplatzhalter, keine bestätigte Beginnzeit.',
      ),
      'Uhrzeit nicht angegeben.',
    );
  });
  test('ordinary notes and links remain unchanged', () {
    expect(
      calendarEntryDisplayText('Treffpunkt: Eingang\nhttps://example.com'),
      'Treffpunkt: Eingang\nhttps://example.com',
    );
    expect(calendarEntryDisplayText(null), '');
  });
}
