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
      _ => link.status,
    };
  }

  final base = settingsProfileSubtitle(profile);
  if (isActive) {
    return base == 'Persönliche Angaben bearbeiten'
        ? 'Aktiv'
        : '$base · Aktiv';
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
    firstName: loaded?.firstName ?? link.childFirstName,
    lastName: loaded?.lastName ?? link.childLastName,
    className: loaded?.className ?? link.childClassName,
    schoolTrack: loaded?.schoolTrack,
    voice: loaded?.voice,
    role: loaded?.role,
    choir: loaded?.choir,
    diet: loaded?.diet,
  );
}
