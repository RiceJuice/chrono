import 'package:chronoapp/core/database/backend_enums.dart';
import 'package:chronoapp/features/settings/data/models/profile_snapshot.dart';
import 'package:chronoapp/features/settings/presentation/helpers/settings_icons.dart';
import 'package:chronoapp/features/settings/presentation/helpers/settings_profile_display.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_island.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_section_label.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_tile.dart';
import 'package:flutter/material.dart';

const settingsRoleOptions = <String>['Schüler', 'Elternteil'];
const settingsVoiceOptions = <String>['Sopran', 'Alt', 'Tenor', 'Bass'];
final settingsSchoolTrackOptions = BackendSchoolTrack.values
    .where((item) => item != BackendSchoolTrack.unknown)
    .map((item) => item.displayLabel)
    .toList(growable: false);
final settingsDietOptions = <String>[
  BackendDiet.noRestriction.displayLabel,
  BackendDiet.vegetarian.displayLabel,
];

/// Schule-, Chor- und Sonstiges-Sektionen der Einstellungen.
class SettingsProfileSections extends StatelessWidget {
  const SettingsProfileSections({
    super.key,
    required this.profile,
    this.readOnly = false,
    this.showCalendarDefaults = true,
    this.onEditRole,
    this.onEditClassName,
    this.onEditSchoolTrack,
    this.onEditChoir,
    this.onEditVoice,
    this.onEditDiet,
  });

  final ProfileSnapshot? profile;
  final bool readOnly;
  /// Kalender-Standardwerte separat in [SettingsCalendarDefaultsSection].
  final bool showCalendarDefaults;
  final VoidCallback? onEditRole;
  final VoidCallback? onEditClassName;
  final VoidCallback? onEditSchoolTrack;
  final VoidCallback? onEditChoir;
  final VoidCallback? onEditVoice;
  final VoidCallback? onEditDiet;

  static const Widget _noTrailing = SizedBox.shrink();

  @override
  Widget build(BuildContext context) {
    final canEdit = !readOnly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SettingsSectionLabel(title: 'Schule', top: 22),
        SettingsIsland(
          children: [
            SettingsTile(
              title: 'Rolle',
              subtitle: settingsValueOrFallback(profile?.role),
              icon: SettingsIcons.role,
              enabled: canEdit,
              onTap: canEdit ? onEditRole : null,
              trailing: canEdit ? null : _noTrailing,
            ),
            if (!showCalendarDefaults) ...[
              SettingsTile(
                title: 'Klasse',
                subtitle: settingsValueOrFallback(profile?.className),
                icon: SettingsIcons.schoolClass,
                enabled: canEdit,
                onTap: canEdit ? onEditClassName : null,
                trailing: canEdit ? null : _noTrailing,
              ),
              SettingsTile(
                title: 'Schulzweig',
                subtitle: settingsValueOrFallback(
                  schoolTrackDisplayLabel(profile?.schoolTrack),
                ),
                icon: SettingsIcons.schoolTrack,
                enabled: canEdit,
                onTap: canEdit ? onEditSchoolTrack : null,
                trailing: canEdit ? null : _noTrailing,
              ),
            ],
          ],
        ),
        if (showCalendarDefaults) ...[
          const SettingsSectionLabel(title: 'Chor'),
          SettingsIsland(
            children: [
              SettingsTile(
                title: 'Chor',
                subtitle: settingsValueOrFallback(
                  choirDisplayLabel(profile?.choir),
                ),
                icon: SettingsIcons.choir,
                enabled: canEdit,
                onTap: canEdit ? onEditChoir : null,
                trailing: canEdit ? null : _noTrailing,
              ),
              SettingsTile(
                title: 'Stimme',
                subtitle: settingsValueOrFallback(profile?.voice),
                icon: SettingsIcons.voice,
                enabled: canEdit,
                onTap: canEdit ? onEditVoice : null,
                trailing: canEdit ? null : _noTrailing,
              ),
            ],
          ),
          const SettingsSectionLabel(title: 'Sonstiges'),
          SettingsIsland(
            children: [
              SettingsTile(
                title: 'Ernährung',
                subtitle: settingsValueOrFallback(
                  dietDisplayLabel(profile?.diet),
                ),
                icon: SettingsIcons.diet,
                enabled: canEdit,
                onTap: canEdit ? onEditDiet : null,
                trailing: canEdit ? null : _noTrailing,
              ),
            ],
          ),
        ],
      ],
    );
  }
}
