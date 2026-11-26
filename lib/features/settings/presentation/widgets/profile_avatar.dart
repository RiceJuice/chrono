import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/profile_snapshot.dart';
import '../providers/profile_avatar_provider.dart';
import 'profile_appearance.dart';

String profileInitials(ProfileSnapshot? profile) {
  final first = (profile?.firstName ?? '').trim();
  final last = (profile?.lastName ?? '').trim();
  final initials =
      '${first.isEmpty ? '' : first.characters.first}'
              '${last.isEmpty ? '' : last.characters.first}'
          .toUpperCase();
  return initials.isEmpty ? 'CH' : initials;
}

class ProfileAvatarView extends StatelessWidget {
  const ProfileAvatarView({
    super.key,
    required this.profile,
    this.radius = 28,
    this.color,
    this.photo,
  });

  final ProfileSnapshot? profile;
  final double radius;
  final int? color;
  final Uint8List? photo;

  @override
  Widget build(BuildContext context) {
    final background = color == null
        ? profileDefaultBackground(context)
        : Color(color!);
    final foreground = color == null
        ? profileDefaultForeground(context)
        : (background.computeLuminance() > 0.45
              ? Colors.black87
              : Colors.white);
    final initials = Center(
      child: Text(
        profileInitials(profile),
        style: TextStyle(
          fontSize: radius * 0.65,
          fontWeight: FontWeight.w600,
          color: foreground,
          letterSpacing: -0.5,
        ),
      ),
    );
    return Semantics(
      image: true,
      label: photo == null ? 'Profilbild mit Initialen' : 'Eigenes Profilfoto',
      child: ClipOval(
        child: SizedBox.square(
          dimension: radius * 2,
          child: ColoredBox(
            color: background,
            child: photo == null
                ? initials
                : Image.memory(
                    photo!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => initials,
                  ),
          ),
        ),
      ),
    );
  }
}

class OwnProfileAvatar extends ConsumerWidget {
  const OwnProfileAvatar({super.key, required this.profile, this.radius = 28});
  final ProfileSnapshot? profile;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatar = ref.watch(profileAvatarProvider).asData?.value;
    final photo = ref.watch(profileAvatarPhotoProvider).asData?.value;
    return ProfileAvatarView(
      profile: profile,
      radius: radius,
      color: avatar?.color,
      photo: photo,
    );
  }
}
