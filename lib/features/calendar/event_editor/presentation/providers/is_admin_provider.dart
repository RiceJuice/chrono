import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/auth/profile_role_ids.dart';
import '../../../../settings/presentation/providers/settings_profile_providers.dart';

final isAdminProvider = Provider<bool>((ref) {
  final profile = ref.watch(syncedProfileProvider).asData?.value;
  return profile?.role?.trim() == ProfileRoleIds.admin;
});
