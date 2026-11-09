import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../event_editor/presentation/providers/is_admin_provider.dart';

/// Meal photos are only displayed for a confirmed admin profile.
final showMealImagesProvider = Provider<bool>((ref) {
  return ref.watch(isAdminProvider);
});
