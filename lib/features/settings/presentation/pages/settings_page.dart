import 'package:chronoapp/core/database/backend_connector.dart';
import 'package:chronoapp/core/database/backend_enums.dart';
import 'package:chronoapp/core/theme/theme_mode_provider.dart';
import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:chronoapp/features/calendar/presentation/providers/filter/calendar/calendar_filters_provider.dart';
import 'package:chronoapp/features/calendar/presentation/providers/filter/search/search_filters_provider.dart';
import 'package:chronoapp/features/login/presentation/providers/auth_repository_provider.dart';
import 'package:chronoapp/features/login/presentation/providers/profile_gate_provider.dart';
import 'package:chronoapp/features/login/presentation/providers/klassen_provider.dart';
import 'package:chronoapp/features/login/data/auth_repository.dart';
import 'package:chronoapp/features/settings/data/models/profile_snapshot.dart';
import 'package:chronoapp/features/settings/presentation/helpers/settings_profile_display.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_choice_action_sheet.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_footer.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_island.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_logout_button.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_profile_header_card.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_section_label.dart';
import 'package:chronoapp/features/settings/presentation/pages/settings_edit_personal_data_page.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_sliver_header.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_profile_providers.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _saving = false;

  late final ScrollController _scrollController;

  /// 0–1 aus Scroll-Offset (linear); Sichtbarkeit der AppBar-Überschrift: ease-in.
  double _appBarTitleLinear = 0;

  /// Scroll-Offset, ab dem der AppBar-Titel sichtbar wird / voll sichtbar ist.
  static const _appBarTitleFadeStart = 28.0;
  static const _appBarTitleFadeEnd = 88.0;

  static const _roleOptions = <String>['Schüler', 'Elternteil'];
  static const _voiceOptions = <String>['Sopran', 'Alt', 'Tenor', 'Bass'];
  static final _schoolTrackOptions = BackendSchoolTrack.values
      .where((item) => item != BackendSchoolTrack.unknown)
      .map((item) => item.displayLabel)
      .toList(growable: false);
  static final _dietOptions = <String>[
    BackendDiet.noRestriction.displayLabel,
    BackendDiet.vegetarian.displayLabel,
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final o = _scrollController.offset;
    final span = _appBarTitleFadeEnd - _appBarTitleFadeStart;
    final p = span <= 0
        ? (o >= _appBarTitleFadeEnd ? 1.0 : 0.0)
        : ((o - _appBarTitleFadeStart) / span).clamp(0.0, 1.0);
    if (p == _appBarTitleLinear) return;
    setState(() => _appBarTitleLinear = p);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(syncedProfileProvider);
    final classesAsync = ref.watch(availableClassesProvider);
    final themeMode = ref.watch(appThemeModeProvider);

    final theme = Theme.of(context);
    final bg = theme.scaffoldBackgroundColor;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 44,
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        centerTitle: true,
        title: Opacity(
          opacity: Curves.easeIn.transform(_appBarTitleLinear.clamp(0.0, 1.0)),
          child: Text(
            SettingsSliverHeader.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 18,
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SettingsSliverHeader.largeTitleSliver(context),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            sliver: SliverList.list(
              children: [
                const SizedBox(height: 18),
                profileAsync.when(
                  data: (profile) =>
                      SettingsProfileHeaderCard(profile: profile),
                  loading: () => const _SettingsLoadingIsland(
                    message: 'Profil wird geladen...',
                  ),
                  error: (error, _) => _SettingsErrorIsland(
                    message: 'Profil konnte nicht geladen werden',
                    detail: error.toString(),
                  ),
                ),
                ...profileAsync.maybeWhen(
                  data: (profile) => [
                    const SettingsSectionLabel(title: 'Persönlich', top: 22),
                    SettingsIsland(
                      children: [
                        SettingsTile(
                          title: 'Name',
                          subtitle: settingsProfileName(profile),
                          icon: Icons.person_outline_rounded,
                          enabled: !_saving,
                          onTap: () => _openEditPersonalData(profile),
                        ),
                      ],
                    ),
                    const SettingsSectionLabel(title: 'Schule'),
                    SettingsIsland(
                      children: [
                        SettingsTile(
                          title: 'Rolle',
                          subtitle: settingsValueOrFallback(profile?.role),
                          icon: Icons.groups_outlined,
                          enabled: !_saving,
                          onTap: () => _editChoiceField(
                            title: 'Rolle auswählen',
                            initialValue: profile?.role,
                            options: _roleOptions,
                            onSave: (value) => _updateProfile(role: value),
                          ),
                        ),
                        SettingsTile(
                          title: 'Klasse',
                          subtitle: settingsValueOrFallback(profile?.className),
                          icon: Icons.school_outlined,
                          enabled: !_saving,
                          onTap: () => _editChoiceField(
                            title: 'Klasse auswählen',
                            initialValue: profile?.className,
                            options: classesAsync.maybeWhen(
                              data: (classes) => classes,
                              orElse: () => const [],
                            ),
                            onSave: (value) => _updateProfile(className: value),
                          ),
                        ),
                        SettingsTile(
                          title: 'Schulzweig',
                          subtitle: settingsValueOrFallback(
                            schoolTrackDisplayLabel(profile?.schoolTrack),
                          ),
                          icon: Icons.account_tree_outlined,
                          enabled: !_saving,
                          onTap: () => _editChoiceField(
                            title: 'Schulzweig auswählen',
                            initialValue: schoolTrackDisplayLabel(
                              profile?.schoolTrack,
                            ),
                            options: _schoolTrackOptions,
                            onSave: (value) =>
                                _updateProfile(schoolTrack: value),
                          ),
                        ),
                      ],
                    ),
                    const SettingsSectionLabel(title: 'Chor'),
                    SettingsIsland(
                      children: [
                        SettingsTile(
                          title: 'Chor',
                          subtitle: settingsValueOrFallback(
                            choirDisplayLabel(profile?.choir),
                          ),
                          icon: Icons.church_outlined,
                          enabled: !_saving,
                          onTap: () => _editChoiceField(
                            title: 'Chor auswählen',
                            initialValue: choirDisplayLabel(profile?.choir),
                            options: BackendChoir.values
                                .where((item) => item != BackendChoir.unknown)
                                .map((item) => item.displayLabel)
                                .toList(),
                            onSave: (value) => _updateProfile(choir: value),
                          ),
                        ),
                        SettingsTile(
                          title: 'Stimme',
                          subtitle: settingsValueOrFallback(profile?.voice),
                          icon: Icons.record_voice_over_outlined,
                          enabled: !_saving,
                          onTap: () => _editChoiceField(
                            title: 'Stimme auswählen',
                            initialValue: profile?.voice,
                            options: _voiceOptions,
                            onSave: (value) => _updateProfile(voice: value),
                          ),
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
                          icon: Icons.restaurant_outlined,
                          enabled: !_saving,
                          onTap: () => _editChoiceField(
                            title: 'Ernährung auswählen',
                            initialValue: dietDisplayLabel(profile?.diet),
                            options: _dietOptions,
                            onSave: (value) => _updateProfile(diet: value),
                          ),
                        ),
                      ],
                    ),
                  ],
                  orElse: () => const [],
                ),
                const SettingsSectionLabel(title: 'Darstellung'),
                SettingsIsland(
                  children: [
                    SettingsTile(
                      title: 'Design',
                      icon: Icons.dark_mode_outlined,
                      subtitle: _themeModeLabel(themeMode),
                      onTap: () => _editThemeMode(themeMode),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                SettingsLogoutButton(
                  onPressed: () => BackendConnector.logout(context),
                ),
                const SettingsFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openEditPersonalData(ProfileSnapshot? profile) {
    HapticFeedback.heavyImpact();
    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        builder: (context) => SettingsEditPersonalDataPage(
          initialFirstName: profile?.firstName,
          initialLastName: profile?.lastName,
        ),
      ),
    );
  }

  Future<void> _editChoiceField({
    required String title,
    required String? initialValue,
    required List<String> options,
    required Future<void> Function(String) onSave,
  }) async {
    if (options.isEmpty) {
      if (!mounted) return;
      _showErrorSnackBar('Keine Optionen verfügbar.');
      return;
    }

    HapticFeedback.heavyImpact();
    final value = await AppModalSheet.show<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return AppModalSheetChrome(
          constraints: appModalChoiceSheetConstraints(context),
          child: SettingsChoiceActionSheet(
            title: title,
            options: options,
            initialValue: initialValue,
          ),
        );
      },
    );

    if (value == null) return;
    await onSave(value);
  }

  Future<void> _updateProfile({
    String? firstName,
    String? lastName,
    String? className,
    String? schoolTrack,
    String? voice,
    String? diet,
    String? role,
    String? choir,
  }) async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      await ref
          .read(authRepositoryProvider)
          .updateProfile(
            firstName: firstName,
            lastName: lastName,
            className: className,
            schoolTrack: schoolTrack,
            voice: voice,
            diet: diet,
            role: role,
            choir: choir,
          );
      await ref.read(profileGateProvider).refresh();
      ref.invalidate(syncedProfileProvider);
      ref
          .read(calendarFiltersProvider.notifier)
          .applyProfileFilterChanges(
            choir: choir,
            voice: voice,
            className: className,
            schoolTrack: schoolTrack,
          );
      ref
          .read(searchFiltersProvider.notifier)
          .initializeFromCalendar(ref.read(calendarFiltersProvider));
    } on AuthRepositoryException catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.message);
    } catch (_) {
      if (!mounted) return;
      _showErrorSnackBar(
        'Änderung konnte nicht gespeichert werden. Bitte erneut versuchen.',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showErrorSnackBar(String message) {
    showAppToast(context, message, kind: AppToastKind.error);
  }

  Future<void> _editThemeMode(ThemeMode currentMode) async {
    await _editChoiceField(
      title: 'Design auswählen',
      initialValue: _themeModeLabel(currentMode),
      options: _themeModeLabels,
      onSave: (value) => _setThemeMode(_themeModeFromLabel(value)),
    );
  }

  Future<void> _setThemeMode(ThemeMode themeMode) async {
    try {
      await ref.read(appThemeModeProvider.notifier).setThemeMode(themeMode);
    } catch (_) {
      if (!mounted) return;
      _showErrorSnackBar(
        'Darstellung konnte nicht gespeichert werden. Bitte erneut versuchen.',
      );
    }
  }
}

const _themeModeLabels = <String>['Systemstandard', 'Hell', 'Dunkel'];

String _themeModeLabel(ThemeMode themeMode) {
  return switch (themeMode) {
    ThemeMode.system => 'Systemstandard',
    ThemeMode.light => 'Hell',
    ThemeMode.dark => 'Dunkel',
  };
}

ThemeMode _themeModeFromLabel(String label) {
  return switch (label) {
    'Hell' => ThemeMode.light,
    'Dunkel' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}

class _SettingsLoadingIsland extends StatelessWidget {
  const _SettingsLoadingIsland({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SettingsIsland(
      children: [
        ListTile(
          leading: const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          title: Text(message),
        ),
      ],
    );
  }
}

class _SettingsErrorIsland extends StatelessWidget {
  const _SettingsErrorIsland({required this.message, required this.detail});

  final String message;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return SettingsIsland(
      children: [
        ListTile(
          leading: const Icon(Icons.error_outline_rounded),
          title: Text(message),
          subtitle: Text(detail, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
