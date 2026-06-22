import 'package:chronoapp/features/calendar/live_activity/live_activity_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseScheduleLiveActivityEventId erkennt Custom-Scheme', () {
    expect(
      parseScheduleLiveActivityEventId(
        Uri.parse('chronoapp://schedule?eventId=abc-123'),
      ),
      'abc-123',
    );
  });

  test('parseScheduleLiveActivityEventId erkennt GoRouter-Pfad', () {
    expect(
      parseScheduleLiveActivityEventId(
        Uri.parse('/schedule?eventId=abc-123'),
      ),
      'abc-123',
    );
  });

  test('parseScheduleLiveActivityEventId ignoriert andere Routen', () {
    expect(
      parseScheduleLiveActivityEventId(
        Uri.parse('chronoapp://auth-callback'),
      ),
      isNull,
    );
  });
}
