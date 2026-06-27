import 'package:chronoapp/features/calendar/domain/filter/calendar_filters_state.dart';
import 'package:chronoapp/features/login/domain/models/guardian_child_share_permissions.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_child_permissions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('guardianCalendarTypeConfigurable', () {
    const permissions = GuardianChildSharePermissions(
      shareSchool: true,
      shareMeal: false,
      shareChoir: true,
    );

    test('zeigt alle Bereiche für Nicht-Eltern', () {
      expect(
        guardianCalendarTypeConfigurable(
          isGuardianViewer: false,
          permissions: GuardianChildSharePermissions.minimal,
          calendar: CalendarVisibility.meal,
        ),
        isTrue,
      );
    });

    test('blendet nicht freigegebene Bereiche für Eltern aus', () {
      expect(
        guardianCalendarTypeConfigurable(
          isGuardianViewer: true,
          permissions: permissions,
          calendar: CalendarVisibility.school,
        ),
        isTrue,
      );
      expect(
        guardianCalendarTypeConfigurable(
          isGuardianViewer: true,
          permissions: permissions,
          calendar: CalendarVisibility.meal,
        ),
        isFalse,
      );
      expect(
        guardianCalendarTypeConfigurable(
          isGuardianViewer: true,
          permissions: permissions,
          calendar: CalendarVisibility.choir,
        ),
        isTrue,
      );
    });
  });
}
