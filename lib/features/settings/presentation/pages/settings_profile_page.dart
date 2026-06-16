import 'package:chronoapp/core/widgets/app_dialog.dart';
import 'package:chronoapp/core/widgets/app_glass_back_button.dart';
import 'package:chronoapp/core/widgets/main_shell_scaffold.dart';
import 'package:chronoapp/features/login/presentation/providers/auth_repository_provider.dart';
import 'package:chronoapp/features/settings/data/models/profile_snapshot.dart';
import 'package:chronoapp/features/settings/presentation/helpers/settings_icons.dart';
import 'package:chronoapp/features/settings/presentation/helpers/settings_profile_display.dart';
import 'package:chronoapp/features/settings/presentation/pages/settings_change_password_page.dart';
import 'package:chronoapp/features/settings/presentation/pages/settings_delete_account_page.dart';
import 'package:chronoapp/features/settings/presentation/pages/settings_edit_personal_data_page.dart';
import 'package:chronoapp/features/settings/presentation/providers/settings_profile_providers.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_island.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_profile_header_card.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_section_label.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsProfilePage extends ConsumerStatefulWidget {
  const SettingsProfilePage({super.key});

  @override
  ConsumerState<SettingsProfilePage> createState() =>
      _SettingsProfilePageState();
}

class _SettingsProfilePageState extends ConsumerState<SettingsProfilePage> {
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(syncedProfileProvider);
    final canChangePassword = ref.watch(authRepositoryProvider).canChangePassword;
    final theme = Theme.of(context);
    final bg = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        toolbarHeight: 44,
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: AppGlassBackButton(),
        ),
        leadingWidth: 56,
        centerTitle: true,
        title: Text(
          'Dein Profil',
          style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),
        ),
      ),
      body: profileAsync.when(
        data: (profile) => ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            24 + mainShellBottomContentInset(context),
          ),
          children: [
            SettingsProfileHeaderCard(profile: profile),
            const SettingsSectionLabel(title: 'Konto', top: 18),
            SettingsIsland(
              children: [
                SettingsTile(
                  title: 'Name',
                  subtitle: settingsProfileName(profile),
                  icon: SettingsIcons.name,
                  onTap: () => _openEditPersonalData(profile),
                ),
                if (canChangePassword)
                  SettingsTile(
                    title: 'Passwort ändern',
                    icon: SettingsIcons.password,
                    onTap: _openChangePassword,
                  ),
                SettingsTile(
                  title: 'Konto unwiderruflich löschen',
                  icon: SettingsIcons.deleteAccount,
                  isDestructive: true,
                  onTap: _openDeleteAccount,
                ),
              ],
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Profil konnte nicht geladen werden.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  void _openEditPersonalData(ProfileSnapshot? profile) {
    HapticFeedback.heavyImpact();
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => SettingsEditPersonalDataPage(
          initialFirstName: profile?.firstName,
          initialLastName: profile?.lastName,
        ),
      ),
    );
  }

  void _openChangePassword() {
    HapticFeedback.heavyImpact();
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => const SettingsChangePasswordPage(),
      ),
    );
  }

  Future<void> _openDeleteAccount() async {
    HapticFeedback.heavyImpact();
    final proceed = await showAppConfirmDialog(
      context: context,
      title: 'Konto wirklich löschen?',
      message:
          'Du bist dabei, dein Konto dauerhaft zu löschen. '
          'Alle Daten gehen verloren und können nicht wiederhergestellt werden.',
      confirmLabel: 'Weiter zur Löschung',
      cancelLabel: 'Abbrechen',
      confirmRole: AppDialogActionRole.destructive,
    );
    if (!proceed || !mounted) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => const SettingsDeleteAccountPage(),
      ),
    );
  }
}
