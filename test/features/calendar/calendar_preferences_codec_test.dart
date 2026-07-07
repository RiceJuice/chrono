import 'package:chronoapp/features/calendar/data/calendar_preferences_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalendarPreferencesCodec.decodeEventChangeNotifications', () {
    test('gibt true zurück wenn Schlüssel fehlt', () {
      expect(
        CalendarPreferencesCodec.decodeEventChangeNotifications(null),
        isTrue,
      );
      expect(
        CalendarPreferencesCodec.decodeEventChangeNotifications('{}'),
        isTrue,
      );
    });

    test('liest bool und String', () {
      expect(
        CalendarPreferencesCodec.decodeEventChangeNotifications(
          '{"event_change_notifications": false}',
        ),
        isFalse,
      );
      expect(
        CalendarPreferencesCodec.decodeEventChangeNotifications(
          '{"event_change_notifications": "false"}',
        ),
        isFalse,
      );
      expect(
        CalendarPreferencesCodec.decodeEventChangeNotifications(
          '{"event_change_notifications": true}',
        ),
        isTrue,
      );
    });
  });

  group('CalendarPreferencesCodec.encodeEventChangeNotifications', () {
    test('entfernt Schlüssel bei aktiv (Standard)', () {
      final encoded = CalendarPreferencesCodec.encodeEventChangeNotifications(
        existingPreferences: '{"event_change_notifications": false}',
        enabled: true,
      );
      expect(encoded, '{}');
    });

    test('behält andere Felder', () {
      final encoded = CalendarPreferencesCodec.encodeEventChangeNotifications(
        existingPreferences:
            '{"subject_accents":{"math":"#ff0000"},"event_change_notifications":false}',
        enabled: true,
      );
      expect(
        CalendarPreferencesCodec.decodeRoot(encoded)['subject_accents'],
        isNotNull,
      );
      expect(
        CalendarPreferencesCodec.decodeEventChangeNotifications(encoded),
        isTrue,
      );
    });

    test('speichert false explizit', () {
      final encoded = CalendarPreferencesCodec.encodeEventChangeNotifications(
        existingPreferences: null,
        enabled: false,
      );
      expect(
        CalendarPreferencesCodec.decodeEventChangeNotifications(encoded),
        isFalse,
      );
    });
  });

  group('CalendarPreferencesCodec.decodeShowMealImages', () {
    test('gibt true zurück wenn Schlüssel fehlt', () {
      expect(CalendarPreferencesCodec.decodeShowMealImages(null), isTrue);
      expect(CalendarPreferencesCodec.decodeShowMealImages('{}'), isTrue);
    });

    test('liest false explizit', () {
      expect(
        CalendarPreferencesCodec.decodeShowMealImages(
          '{"show_meal_images": false}',
        ),
        isFalse,
      );
    });
  });

  group('CalendarPreferencesCodec.encodeShowMealImages', () {
    test('entfernt Schlüssel bei aktiv (Standard)', () {
      final encoded = CalendarPreferencesCodec.encodeShowMealImages(
        existingPreferences: '{"show_meal_images": false}',
        enabled: true,
      );
      expect(encoded, '{}');
    });

    test('speichert false explizit', () {
      final encoded = CalendarPreferencesCodec.encodeShowMealImages(
        existingPreferences: null,
        enabled: false,
      );
      expect(CalendarPreferencesCodec.decodeShowMealImages(encoded), isFalse);
    });
  });
}
