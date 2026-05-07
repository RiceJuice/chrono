import 'package:chronoapp/core/database/backend_enums.dart';
import 'package:chronoapp/features/settings/data/models/profile_snapshot.dart';

String settingsValueOrFallback(String? value) {
  final text = (value ?? '').trim();
  return text.isEmpty ? 'Nicht gesetzt' : text;
}

String settingsProfileName(ProfileSnapshot? profile) {
  final parts = [
    profile?.firstName,
    profile?.lastName,
  ].where((part) => (part ?? '').trim().isNotEmpty);
  final name = parts.map((part) => part!.trim()).join(' ');
  return name.isEmpty ? 'Profil vervollständigen' : name;
}

String settingsProfileSubtitle(ProfileSnapshot? profile) {
  final className = (profile?.className ?? '').trim();
  final role = (profile?.role ?? '').trim();
  if (className.isNotEmpty && role.isNotEmpty) return '$role · $className';
  if (className.isNotEmpty) return className;
  if (role.isNotEmpty) return role;
  return 'Persönliche Angaben bearbeiten';
}

String? choirDisplayLabel(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final choir = BackendChoirCodec.fromBackend(raw);
  if (choir != BackendChoir.unknown) return choir.displayLabel;
  return raw.trim();
}

String? dietDisplayLabel(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final diet = BackendDietCodec.fromBackend(raw);
  if (diet != BackendDiet.unknown) return diet.displayLabel;
  return raw.trim();
}

String? schoolTrackDisplayLabel(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final schoolTrack = BackendSchoolTrackCodec.fromBackend(raw);
  if (schoolTrack != BackendSchoolTrack.unknown) {
    return schoolTrack.displayLabel;
  }
  return raw.trim();
}
