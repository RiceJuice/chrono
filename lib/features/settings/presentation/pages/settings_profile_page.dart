import 'package:chronoapp/core/widgets/app_dialog.dart';
import 'package:chronoapp/core/widgets/app_glass_back_button.dart';
import 'package:chronoapp/core/widgets/app_glass_icon_button.dart';
import 'package:chronoapp/features/settings/presentation/widgets/profile_appearance.dart';
import 'package:chronoapp/features/settings/presentation/widgets/profile_page_layout.dart';
import 'package:chronoapp/features/login/presentation/providers/auth_repository_provider.dart';
import 'package:chronoapp/features/settings/data/models/profile_snapshot.dart';
import 'package:chronoapp/features/settings/presentation/helpers/settings_icons.dart';
import 'package:chronoapp/features/settings/presentation/helpers/settings_profile_display.dart';
import 'package:chronoapp/features/settings/presentation/pages/settings_change_password_page.dart';
import 'package:chronoapp/features/settings/presentation/pages/settings_delete_account_page.dart';
import 'package:chronoapp/features/settings/presentation/pages/settings_edit_personal_data_page.dart';
import 'package:chronoapp/features/settings/presentation/providers/settings_profile_providers.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_island.dart';
import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:chronoapp/features/settings/presentation/providers/profile_avatar_provider.dart';
import 'package:chronoapp/features/settings/presentation/widgets/profile_avatar.dart';
import 'package:chronoapp/features/settings/presentation/widgets/profile_avatar_editor.dart';
import 'package:chronoapp/features/settings/presentation/widgets/guardian_parent_access_section.dart';
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
    final canChangePassword = ref
        .watch(authRepositoryProvider)
        .canChangePassword;
    final theme = Theme.of(context);
    final bg = isNativeAppleProfile
        ? (theme.brightness == Brightness.dark
              ? const Color(0xff000000)
              : const Color(0xfff2f2f7))
        : theme.scaffoldBackgroundColor;

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
          'Profil anpassen',
          style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),
        ),
      ),
      body: profileAsync.when(
        data: (profile) => ProfilePageLayout(
          header: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Semantics(
                  button: true,
                  label: 'Profilbild bearbeiten',
                  child: GestureDetector(
                    onTap: () => _editAvatar(profile),
                    child: Stack(
                      children: [
                        OwnProfileAvatar(
                          profile: profile,
                          radius: isNativeAppleProfile ? 58 : 52,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: useNativeProfileGlass
                              ? AppGlassIconButton(
                                  icon: AppGlassIconButton.attachMediaIcon,
                                  tooltip: 'Profilbild bearbeiten',
                                  iconSize: 16,
                                  onPressed: () => _editAvatar(profile),
                                )
                              : Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: profileDefaultBackground(context),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: bg, width: 3),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt_rounded,
                                    size: 16,
                                    color: profileDefaultForeground(context),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  settingsProfileName(profile),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: isNativeAppleProfile
                        ? FontWeight.w600
                        : FontWeight.w700,
                    fontSize: isNativeAppleProfile ? 30 : null,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Dein persönlicher Auftritt in Chrono',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                ProfileActionButton(
                  onPressed: () => _editAvatar(profile),
                  label: 'Profilbild bearbeiten',
                ),
              ],
            ),
          ),
          account: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SettingsSectionLabel(title: 'Persönliche Angaben', top: 0),
              SettingsIsland(
                children: [
                  SettingsTile(
                    title: 'Name',
                    subtitle: settingsValueOrFallback(
                      [profile?.firstName, profile?.lastName]
                          .whereType<String>()
                          .map((part) => part.trim())
                          .where((part) => part.isNotEmpty)
                          .join(' '),
                    ),
                    icon: SettingsIcons.name,
                    onTap: () => _openEditPersonalData(profile),
                  ),
                  if (canChangePassword)
                    SettingsTile(
                      title: 'Passwort ändern',
                      icon: SettingsIcons.password,
                      onTap: _openChangePassword,
                    ),
                ],
              ),
              const GuardianParentAccessSection(),
              const SizedBox(height: 28),
              SettingsIsland(
                children: [
                  SettingsTile(
                    title: 'Konto löschen',
                    icon: SettingsIcons.deleteAccount,
                    isDestructive: true,
                    onTap: _openDeleteAccount,
                  ),
                ],
              ),
            ],
          ),
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

  Future<void> _editAvatar(ProfileSnapshot? profile) async {
    HapticFeedback.selectionClick();
    final avatar = await ref.read(profileAvatarProvider.future);
    if (!mounted) return;
    final photo = ref.read(profileAvatarPhotoProvider).asData?.value;
    await AppModalSheet.show<void>(
      context: context,
      showDragHandle: !isNativeAppleProfile,
      useSafeArea: true,
      sheetAnimationStyle: kSettingsChoiceSheetMotion,
      builder: (_) => ProfileAvatarEditor(
        profile: profile,
        initial: avatar,
        initialPhoto: photo,
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
