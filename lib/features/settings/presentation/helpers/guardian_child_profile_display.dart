import 'package:chronoapp/features/login/domain/models/guardian_child_link.dart';
import 'package:chronoapp/features/settings/data/models/profile_snapshot.dart';
import 'package:chronoapp/features/settings/presentation/helpers/settings_profile_display.dart';

bool guardianChildCardIsTappable(GuardianChildLink link) => link.isConfirmed;

String guardianChildCardSubtitle({
  required GuardianChildLink link,
  required ProfileSnapshot? profile,
  required bool isActive,
}) {
  if (!link.isConfirmed) {
    return switch (link.status) {
      GuardianLinkStatus.pending => 'Bestätigung ausstehend',
      GuardianLinkStatus.rejected => 'Verknüpfung abgelehnt',
      GuardianLinkStatus.revoked => 'Verbindung getrennt',
      _ => link.status,
    };
  }

  final base = settingsProfileSubtitle(profile);
  if (isActive) {
    return base == 'Persönliche Angaben bearbeiten' ? 'Aktiv' : '$base · Aktiv';
  }
  return base == 'Persönliche Angaben bearbeiten'
      ? 'Profil anzeigen'
      : '$base · Profil anzeigen';
}

ProfileSnapshot guardianChildProfileSnapshot({
  required GuardianChildLink link,
  required ProfileSnapshot? loaded,
}) {
  return ProfileSnapshot(
    role: null,
    artsSubject: link.isConfirmed && link.sharePermissions.shareSchool
        ? link.childArtsSubject
        : null,
    languageSubject: link.isConfirmed && link.sharePermissions.shareSchool
        ? link.childLanguageSubject
        : null,
    timetableChoices: link.isConfirmed && link.sharePermissions.shareSchool
        ? link.childTimetableChoices.map((k, v) => MapEntry(k, v.toString()))
        : const {},
    firstName: loaded?.firstName ?? link.childFirstName,
    lastName: loaded?.lastName ?? link.childLastName,
    className: link.isConfirmed && link.sharePermissions.shareSchool
        ? link.childClassName
        : null,
    schoolTrack: link.isConfirmed && link.sharePermissions.shareSchool
        ? link.childSchoolTrack
        : null,
    voice: link.isConfirmed && link.sharePermissions.shareChoir
        ? link.childVoice
        : null,
    choir: link.isConfirmed && link.sharePermissions.shareChoir
        ? link.childChoir
        : null,
    diet: link.isConfirmed && link.sharePermissions.shareMeal
        ? link.childDiet
        : null,
  );
}
