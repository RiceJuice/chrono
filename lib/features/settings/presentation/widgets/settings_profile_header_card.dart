import 'package:chronoapp/features/settings/data/models/profile_snapshot.dart';
import 'package:chronoapp/features/settings/presentation/helpers/settings_icons.dart';
import 'package:chronoapp/features/settings/presentation/helpers/settings_profile_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/theme_tokens.dart';

const _domspatzenAssetPath = 'assets/domspatzen.svg';

class SettingsProfileHeaderCard extends StatelessWidget {
  const SettingsProfileHeaderCard({
    super.key,
    required this.profile,
    this.onTap,
  });

  final ProfileSnapshot? profile;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initials = _initials(profile);
    final tappable = onTap != null;

    final content = Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            child: Text(
              initials,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settingsProfileName(profile),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tappable
                      ? _tapHint(profile)
                      : settingsProfileSubtitle(profile),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (tappable)
            PhosphorIcon(
              SettingsIcons.chevron,
              size: 18,
              color: scheme.onSurfaceVariant,
            )
          else
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
        color: scheme.surfaceContainerHigh,
        shape: AppSquircle.shape(AppRadius.xl),
      ),
      child: tappable
          ? Material(
              type: MaterialType.transparency,
              child: InkWell(
                customBorder: AppSquircle.shape(AppRadius.xl),
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
    return 'Konto und Anmeldung';
  }
  return '$subtitle · Konto';
}

String _initials(ProfileSnapshot? profile) {
  final firstName = (profile?.firstName ?? '').trim();
  final lastName = (profile?.lastName ?? '').trim();
  final first = firstName.isEmpty ? '' : firstName.characters.first;
  final last = lastName.isEmpty ? '' : lastName.characters.first;
  final initials = '$first$last'.toUpperCase();
  return initials.isEmpty ? 'CH' : initials;
}
