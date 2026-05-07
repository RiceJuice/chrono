import 'package:chronoapp/features/settings/data/models/profile_snapshot.dart';
import 'package:chronoapp/features/settings/presentation/helpers/settings_profile_display.dart';
import 'package:flutter/material.dart';

class SettingsProfileHeaderCard extends StatelessWidget {
  const SettingsProfileHeaderCard({super.key, required this.profile});

  final ProfileSnapshot? profile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initials = _initials(profile);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    settingsProfileSubtitle(profile),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _initials(ProfileSnapshot? profile) {
  final firstName = (profile?.firstName ?? '').trim();
  final lastName = (profile?.lastName ?? '').trim();
  final first = firstName.isEmpty ? '' : firstName.characters.first;
  final last = lastName.isEmpty ? '' : lastName.characters.first;
  final initials = '$first$last'.toUpperCase();
  return initials.isEmpty ? 'CH' : initials;
}
