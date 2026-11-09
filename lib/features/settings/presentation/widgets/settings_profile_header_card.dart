import 'package:chronoapp/features/settings/data/models/profile_snapshot.dart';
import 'package:chronoapp/features/settings/presentation/helpers/settings_icons.dart';
import 'package:chronoapp/features/settings/presentation/helpers/settings_profile_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/theme_tokens.dart';
import 'profile_avatar.dart';
import 'profile_appearance.dart';

const _domspatzenAssetPath = 'assets/domspatzen.svg';

class SettingsProfileHeaderCard extends StatelessWidget {
  const SettingsProfileHeaderCard({
    super.key,
    required this.profile,
    this.onTap,
    this.subtitleOverride,
    this.compact = false,
    this.showOwnAvatar = false,
  });

  final ProfileSnapshot? profile;
  final VoidCallback? onTap;
  final String? subtitleOverride;
  final bool compact;
  final bool showOwnAvatar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tappable = onTap != null;
    final apple = isNativeAppleProfile;

    final content = Padding(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
          : const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showOwnAvatar)
            OwnProfileAvatar(profile: profile, radius: compact ? 18 : 28)
          else
            ProfileAvatarView(profile: profile, radius: compact ? 18 : 28),
          SizedBox(width: compact ? 12 : 14),
          Expanded(
            child: compact
                ? Text(
                    settingsProfileName(profile),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settingsProfileName(profile),
                        textAlign: TextAlign.start,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: apple
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitleOverride ??
                            (tappable
                                ? _tapHint(profile)
                                : settingsProfileSubtitle(profile)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
          ),
          SizedBox(width: compact ? 8 : 10),
          if (tappable)
            PhosphorIcon(
              SettingsIcons.chevron,
              size: compact ? 16 : 18,
              color: scheme.onSurfaceVariant,
            )
          else if (!compact)
            Opacity(
              opacity: 0.3,
              child: SvgPicture.asset(
                _domspatzenAssetPath,
                height: 24,
                width: 24,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(
                  scheme.onSurfaceVariant,
                  BlendMode.srcIn,
                ),
              ),
            ),
        ],
      ),
    );

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: apple && !compact
            ? (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xff1c1c1e)
                  : Colors.white)
            : compact
            ? scheme.surfaceContainer
            : scheme.surfaceContainerHigh,
        shape: AppSquircle.shape(
          compact
              ? AppRadius.l
              : apple
              ? 26
              : AppRadius.xl,
        ),
      ),
      child: tappable
          ? Material(
              type: MaterialType.transparency,
              child: InkWell(
                customBorder: AppSquircle.shape(
                  compact
                      ? AppRadius.l
                      : apple
                      ? 26
                      : AppRadius.xl,
                ),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
                child: content,
              ),
            )
          : content,
    );
  }
}

String _tapHint(ProfileSnapshot? profile) {
  final subtitle = settingsProfileSubtitle(profile);
  if (subtitle == 'Persönliche Angaben bearbeiten') {
    return 'Profilbild und persönliche Angaben';
  }
  return 'Profil anpassen';
}
