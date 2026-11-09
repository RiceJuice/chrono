import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/profile_avatar.dart';

class ProfileAvatarRepository {
  ProfileAvatarRepository(this.client);

  static const bucket = 'profile_avatars';
  final SupabaseClient client;

  Stream<ProfileAvatar> watch() async* {
    yield ProfileAvatar.fromMetadata(client.auth.currentUser?.userMetadata);
    yield* client.auth.onAuthStateChange.map(
      (event) => ProfileAvatar.fromMetadata(event.session?.user.userMetadata),
    );
  }

  Future<Uint8List?> download(String? path) async {
    if (path == null || !_ownsPath(path)) return null;
    return client.storage.from(bucket).download(path);
  }

  bool _ownsPath(String path) {
    final id = client.auth.currentUser?.id;
    return id != null && path.startsWith('$id/');
  }

  Future<void> save({
    required int? color,
    Uint8List? photo,
    required bool usePhoto,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) throw StateError('Bitte erneut anmelden.');
    final previous = ProfileAvatar.fromMetadata(user.userMetadata);
    String? uploadedPath;
    var path = usePhoto ? previous.path : null;
    try {
      if (usePhoto && photo != null) {
        final bytes = await compute(prepareProfilePhoto, photo);
        uploadedPath =
            '${user.id}/${DateTime.now().microsecondsSinceEpoch}.jpg';
        await client.storage
            .from(bucket)
            .uploadBinary(
              uploadedPath,
              bytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
        path = uploadedPath;
      }
      if (client.auth.currentUser?.id != user.id) {
        throw StateError('Bitte erneut anmelden.');
      }
      if (usePhoto && path == null) {
        throw StateError('Bitte ein Foto auswählen.');
      }
      await client.auth.updateUser(
        UserAttributes(
          data: {
            'chrono_avatar': ProfileAvatar(
              path: path,
              color: color,
            ).toMetadata(),
          },
        ),
      );
    } catch (_) {
      if (uploadedPath != null) await _removeQuietly(uploadedPath);
      rethrow;
    }
    if (previous.path != null && previous.path != path) {
      await _removeQuietly(previous.path!);
    }
  }

  Future<void> _removeQuietly(String path) async {
    if (!_ownsPath(path)) return;
    try {
      await client.storage.from(bucket).remove([path]);
    } catch (_) {
      // The new avatar is already saved; cleanup must not report a failed save.
    }
  }
}

/// Normalizes orientation, crops to a square and strips location/EXIF metadata.
Uint8List prepareProfilePhoto(Uint8List bytes) {
  if (bytes.length > 20 * 1024 * 1024) {
    throw const FormatException('Bitte ein Foto unter 20 MB auswählen.');
  }
  img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } catch (_) {
    throw const FormatException('Foto konnte nicht gelesen werden.');
  }
  if (decoded == null) {
    throw const FormatException('Foto konnte nicht gelesen werden.');
  }
  final square = img.copyResizeCropSquare(
    img.bakeOrientation(decoded),
    size: 512,
  );
  final clean = img.Image(width: 512, height: 512);
  img.compositeImage(clean, square);
  return Uint8List.fromList(img.encodeJpg(clean, quality: 88));
}
