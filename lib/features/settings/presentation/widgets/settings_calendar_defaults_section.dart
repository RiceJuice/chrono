import 'package:chronoapp/features/calendar/domain/filter/calendar_filters_state.dart';
import 'package:chronoapp/features/calendar/presentation/providers/filter/calendar/calendar_filters_provider.dart';
import 'package:chronoapp/features/login/domain/models/profile_gate_data.dart';
import 'package:chronoapp/features/login/presentation/providers/profile_gate_provider.dart';
import 'package:chronoapp/features/settings/data/models/profile_snapshot.dart';
import 'package:chronoapp/features/settings/presentation/helpers/calendar_defaults_display.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_calendar_viewer.dart';
import 'package:chronoapp/features/settings/presentation/helpers/settings_icons.dart';
import 'package:chronoapp/features/settings/presentation/helpers/settings_profile_display.dart';
import 'package:chronoapp/features/settings/presentation/providers/effective_calendar_profile_provider.dart';
import 'package:chronoapp/features/settings/presentation/providers/settings_profile_providers.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_island.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_section_label.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const _noTrailing = SizedBox.shrink();

/// Kalender-Standardwerte (Chor, Stimme, Klasse …) — steuern die Filter-Vorgaben.
class SettingsCalendarDefaultsSection extends ConsumerWidget {
  const SettingsCalendarDefaultsSection({
    super.key,
    this.readOnly = false,
    this.onEditClassName,
    this.onEditSchoolTrack,
    this.onEditChoir,
    this.onEditVoice,
    this.onEditDiet,
  });

  final bool readOnly;
  final VoidCallback? onEditClassName;
  final VoidCallback? onEditSchoolTrack;
  final VoidCallback? onEditChoir;
  final VoidCallback? onEditVoice;
  final VoidCallback? onEditDiet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gate = ref.watch(profileGateDataProvider);
    final filters = ref.watch(calendarFiltersProvider);
    final ownProfile = ref.watch(syncedProfileProvider).asData?.value;
    final usesChildProfile = isGuardianCalendarViewer(
      gate: gate,
      ownProfile: ownProfile,
    );
    final profileAsync = usesChildProfile
        ? ref.watch(effectiveCalendarProfileProvider)
        : ref.watch(syncedProfileProvider);

    return profileAsync.when(
      data: (profile) => _buildContent(
        context,
        profile: profile,
        gate: gate,
        filters: filters,
        usesChildProfile: usesChildProfile,
        effectiveReadOnly: readOnly,
        profileLoading: false,
      ),
      loading: () => _buildContent(
        context,
        profile: null,
        gate: gate,
        filters: filters,
        usesChildProfile: usesChildProfile,
        effectiveReadOnly: readOnly,
        profileLoading: usesChildProfile,
      ),
      error: (error, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SettingsSectionLabel(title: 'Kalender', top: 22),
          SettingsIsland(
            children: [
              ListTile(
                leading: PhosphorIcon(SettingsIcons.error, size: 22),
                title: const Text('Standardwerte konnten nicht geladen werden'),
                subtitle: Text(
                  error.toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required ProfileSnapshot? profile,
    required ProfileGateData gate,
    required CalendarFiltersState filters,
    required bool usesChildProfile,
    required bool effectiveReadOnly,
    required bool profileLoading,
  }) {
    if (usesChildProfile && profile == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SettingsSectionLabel(title: 'Kalender', top: 22),
          SettingsIsland(
            children: [
              ListTile(
                leading: profileLoading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : PhosphorIcon(SettingsIcons.error, size: 22),
                title: Text(
                  profileLoading
                      ? 'Kind-Profil wird geladen...'
                      : 'Kein aktives Kind verknüpft',
                ),
              ),
            ],
          ),
        ],
      );
    }

    final display = resolveCalendarDefaultsDisplay(
      profile: profile,
      gate: usesChildProfile ? null : gate,
      filters: filters,
    );
    return _CalendarDefaultsContent(
      display: display,
      readOnly: effectiveReadOnly,
      guardianHint: usesChildProfile,
      onEditClassName: onEditClassName,
      onEditSchoolTrack: onEditSchoolTrack,
      onEditChoir: onEditChoir,
      onEditVoice: onEditVoice,
      onEditDiet: onEditDiet,
    );
  }
}

class _CalendarDefaultsContent extends StatelessWidget {
  const _CalendarDefaultsContent({
    required this.display,
    required this.readOnly,
    required this.guardianHint,
    this.onEditClassName,
    this.onEditSchoolTrack,
    this.onEditChoir,
    this.onEditVoice,
    this.onEditDiet,
  });

  final CalendarDefaultsDisplay display;
  final bool readOnly;
  final bool guardianHint;
  final VoidCallback? onEditClassName;
  final VoidCallback? onEditSchoolTrack;
  final VoidCallback? onEditChoir;
  final VoidCallback? onEditVoice;
  final VoidCallback? onEditDiet;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canEdit = !readOnly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SettingsSectionLabel(title: 'Kalender', top: 22),
        if (guardianHint)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Standardwerte des aktiven Kindes — Änderungen wirken auf Kalender und Filter.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
        SettingsIsland(
          children: [
            SettingsTile(
              title: 'Chor',
              subtitle: settingsValueOrFallback(display.choir),
              icon: SettingsIcons.choir,
              enabled: canEdit,
              onTap: canEdit ? onEditChoir : null,
              trailing: canEdit ? null : _noTrailing,
            ),
            SettingsTile(
              title: 'Stimme',
              subtitle: settingsValueOrFallback(display.voice),
              icon: SettingsIcons.voice,
              enabled: canEdit,
              onTap: canEdit ? onEditVoice : null,
              trailing: canEdit ? null : _noTrailing,
            ),
            SettingsTile(
              title: 'Klasse',
              subtitle: settingsValueOrFallback(display.className),
              icon: SettingsIcons.schoolClass,
              enabled: canEdit,
              onTap: canEdit ? onEditClassName : null,
              trailing: canEdit ? null : _noTrailing,
            ),
            SettingsTile(
              title: 'Schulzweig',
              subtitle: settingsValueOrFallback(display.schoolTrack),
              icon: SettingsIcons.schoolTrack,
              enabled: canEdit,
              onTap: canEdit ? onEditSchoolTrack : null,
              trailing: canEdit ? null : _noTrailing,
            ),
            SettingsTile(
              title: 'Ernährung',
              subtitle: settingsValueOrFallback(display.diet),
              icon: SettingsIcons.diet,
              enabled: canEdit,
              onTap: canEdit ? onEditDiet : null,
              trailing: canEdit ? null : _noTrailing,
            ),
          ],
        ),
      ],
    );
  }
}
