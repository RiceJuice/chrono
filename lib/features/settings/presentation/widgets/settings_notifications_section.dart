import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:chronoapp/features/settings/presentation/helpers/settings_icons.dart';
import 'package:chronoapp/features/settings/presentation/providers/event_change_notifications_provider.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_island.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_section_label.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Push-Einstellungen für Kalender-bezogene Benachrichtigungen.
class SettingsNotificationsSection extends ConsumerStatefulWidget {
  const SettingsNotificationsSection({super.key});

  @override
  ConsumerState<SettingsNotificationsSection> createState() =>
      _SettingsNotificationsSectionState();
}

class _SettingsNotificationsSectionState
    extends ConsumerState<SettingsNotificationsSection> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final enabledAsync = ref.watch(eventChangeNotificationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SettingsSectionLabel(title: 'Benachrichtigungen', top: 22),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Push bei Änderungen an Terminen, die dich betreffen.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        enabledAsync.when(
          data: (enabled) => SettingsIsland(
            children: [
              SettingsSwitchTile(
                title: 'Terminänderungen',
                icon: SettingsIcons.notifications,
                value: enabled,
                enabled: !_saving,
                onChanged: _setEnabled,
              ),
            ],
          ),
          loading: () => const SettingsIsland(
            children: [
              ListTile(
                leading: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                title: Text('Benachrichtigungen werden geladen...'),
              ),
            ],
          ),
          error: (_, _) => const SettingsIsland(
            children: [
              ListTile(
                title: Text('Benachrichtigungen konnten nicht geladen werden'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _setEnabled(bool enabled) async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      await setEventChangeNotifications(ref, enabled);
    } catch (_) {
      if (!mounted) return;
      showAppToast(
        context,
        'Einstellung konnte nicht gespeichert werden. Bitte erneut versuchen.',
        kind: AppToastKind.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
