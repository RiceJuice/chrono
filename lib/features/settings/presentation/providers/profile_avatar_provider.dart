import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/auth/auth_user_id_provider.dart';
import '../../data/models/profile_avatar.dart';
import '../../data/profile_avatar_repository.dart';

final profileAvatarRepositoryProvider = Provider<ProfileAvatarRepository>(
  (ref) => ProfileAvatarRepository(Supabase.instance.client),
);

final profileAvatarProvider = StreamProvider<ProfileAvatar>(
  (ref) => ref.watch(profileAvatarRepositoryProvider).watch(),
);

final profileAvatarPhotoProvider = FutureProvider<Uint8List?>((ref) {
  ref.watch(authUserIdProvider);
  final avatar = ref.watch(profileAvatarProvider).asData?.value;
  return ref.watch(profileAvatarRepositoryProvider).download(avatar?.path);
});
