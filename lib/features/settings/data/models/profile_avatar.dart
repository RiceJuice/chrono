/// Personal appearance only; never used for permissions or account identity.
class ProfileAvatar {
  const ProfileAvatar({this.path, this.color});

  final String? path;
  final int? color;

  factory ProfileAvatar.fromMetadata(Map<String, dynamic>? metadata) {
    final value = metadata?['chrono_avatar'];
    if (value is! Map) return const ProfileAvatar();
    final path = value['path'];
    final color = value['color'];
    return ProfileAvatar(
      path: path is String && path.isNotEmpty ? path : null,
      color: color is int && color >= 0xff000000 && color <= 0xffffffff
          ? color
          : null,
    );
  }

  Map<String, dynamic> toMetadata() => {'path': path, 'color': color};
}
