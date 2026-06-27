import 'package:chronoapp/core/auth/auth_user_id_provider.dart';
import 'package:chronoapp/features/calendar/domain/filter/calendar_filters_state.dart';
import 'package:chronoapp/features/login/domain/models/guardian_child_share_permissions.dart';
import 'package:chronoapp/features/login/presentation/providers/guardian_link_providers.dart';
import 'package:chronoapp/features/login/presentation/providers/profile_gate_provider.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_active_child_id.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_calendar_viewer.dart';
import 'package:chronoapp/features/settings/presentation/providers/settings_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Freigaben des aktiven Kindes für den eingeloggten Elternteil.
final activeGuardianChildPermissionsProvider =
    Provider<GuardianChildSharePermissions>((ref) {
  final gate = ref.watch(profileGateDataProvider);
  final ownProfile = ref.watch(syncedProfileProvider).asData?.value;
  if (!isGuardianCalendarViewer(gate: gate, ownProfile: ownProfile)) {
    return GuardianChildSharePermissions.minimal;
  }

  final userId = ref.watch(authUserIdProvider).value;
  if (userId == null) return GuardianChildSharePermissions.minimal;

  final linksAsync = ref.watch(guardianLinksProvider);
  return linksAsync.maybeWhen(
    data: (links) {
      final confirmed =
          confirmedGuardianOwnLinks(links: links, guardianId: userId);
      if (confirmed.isEmpty) return GuardianChildSharePermissions.minimal;

      final activeLink = resolveActiveGuardianChildLink(
        confirmed: confirmed,
        activeChildId: gate.activeChildId,
      );
      return activeLink.sharePermissions;
    },
    orElse: () => GuardianChildSharePermissions.minimal,
  );
});

/// Ob der Elternteil den Aufgaben-Tab sehen darf.
final guardianHomeworkTabVisibleProvider = Provider<bool>((ref) {
  final gate = ref.watch(profileGateDataProvider);
  final ownProfile = ref.watch(syncedProfileProvider).asData?.value;
  if (!isGuardianCalendarViewer(gate: gate, ownProfile: ownProfile)) {
    return true;
  }
  return ref.watch(activeGuardianChildPermissionsProvider).shareHomework;
});

/// Elternteil sieht Aufgaben des Kindes nur lesend.
final isGuardianHomeworkReadOnlyProvider = Provider<bool>((ref) {
  final gate = ref.watch(profileGateDataProvider);
  final ownProfile = ref.watch(syncedProfileProvider).asData?.value;
  return isGuardianCalendarViewer(gate: gate, ownProfile: ownProfile);
});

/// Ob ein Kalender-Bereich in den Kalender-Einstellungen sichtbar/konfigurierbar ist.
bool guardianCalendarTypeConfigurable({
  required bool isGuardianViewer,
  required GuardianChildSharePermissions permissions,
  required CalendarVisibility calendar,
}) {
  if (!isGuardianViewer) return true;
  return switch (calendar) {
    CalendarVisibility.school => permissions.shareSchool,
    CalendarVisibility.meal => permissions.shareMeal,
    CalendarVisibility.choir => permissions.shareChoir,
  };
}

/// Ob ein Kalender-Bereich für Eltern ein- statt ausgeblendet werden darf.
bool guardianMayEnableCalendarType({
  required bool isGuardianViewer,
  required GuardianChildSharePermissions permissions,
  required CalendarVisibility calendar,
}) {
  if (!isGuardianViewer) return true;
  return guardianCalendarTypeConfigurable(
    isGuardianViewer: isGuardianViewer,
    permissions: permissions,
    calendar: calendar,
  );
}
