import 'package:chronoapp/core/database/backend_connector.dart';
import 'package:chronoapp/core/theme/theme_mode_provider.dart';
import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:chronoapp/features/calendar/presentation/providers/filter/calendar/calendar_filters_provider.dart';
import 'package:chronoapp/features/settings/presentation/helpers/calendar_defaults_display.dart';
import 'package:chronoapp/features/calendar/presentation/providers/filter/search/search_filters_provider.dart';
import 'package:chronoapp/features/login/domain/models/login_flow_role_ids.dart';
import 'package:chronoapp/features/login/presentation/providers/auth_repository_provider.dart';
import 'package:chronoapp/features/login/presentation/providers/profile_gate_provider.dart';
import 'package:chronoapp/features/login/presentation/providers/klassen_provider.dart';
import 'package:chronoapp/features/login/data/auth_repository.dart';
import 'package:chronoapp/features/settings/presentation/helpers/settings_icons.dart';
import 'package:chronoapp/features/settings/presentation/helpers/settings_profile_display.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_choice_action_sheet.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_choir_carousel_sheet.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_footer.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_island.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_logout_button.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_profile_header_card.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_child_calendar_defaults_update.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_calendar_viewer.dart';
import 'package:chronoapp/features/settings/presentation/providers/effective_calendar_profile_provider.dart';
import 'package:chronoapp/features/settings/data/settings_profile_repository.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_calendar_defaults_section.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_profile_sections.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_section_label.dart';
import 'package:chronoapp/features/settings/presentation/pages/settings_profile_page.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_scroll_top_blur.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_sliver_header.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_profile_providers.dart';
import '../widgets/guardian_children_section.dart';

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

  /// 0–1 für den Top-Blur — erst nach weggescrollter Profilkarte.
  double _topBlurLinear = 0;

  /// Scroll-Offset, ab dem der AppBar-Titel sichtbar wird / voll sichtbar ist.
  static const _appBarTitleFadeStart = 28.0;
  static const _appBarTitleFadeEnd = 88.0;

  /// Scroll-Inhalt bis Unterkante der Profilkarte (Titel + Abstand + Karte).
  static const _largeTitleBlockHeight = 75.0;
  static const _profileCardTopGap = 18.0;
  static const _profileHeaderCardHeight = 92.0;

  double get _profileCardBottomOffset =>
      _largeTitleBlockHeight + _profileCardTopGap + _profileHeaderCardHeight;

  double get _topBlurFadeStart => _profileCardBottomOffset;

  double get _topBlurFadeEnd => _profileCardBottomOffset + 44.0;

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
    final titleSpan = _appBarTitleFadeEnd - _appBarTitleFadeStart;
    final titleP = titleSpan <= 0
        ? (o >= _appBarTitleFadeEnd ? 1.0 : 0.0)
        : ((o - _appBarTitleFadeStart) / titleSpan).clamp(0.0, 1.0);
    final blurSpan = _topBlurFadeEnd - _topBlurFadeStart;
    final blurP = blurSpan <= 0
        ? (o >= _topBlurFadeEnd ? 1.0 : 0.0)
        : ((o - _topBlurFadeStart) / blurSpan).clamp(0.0, 1.0);
    if (titleP == _appBarTitleLinear && blurP == _topBlurLinear) return;
    setState(() {
      _appBarTitleLinear = titleP;
      _topBlurLinear = blurP;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ownProfileAsync = ref.watch(syncedProfileProvider);
    final gateData = ref.watch(profileGateDataProvider);
    final ownProfile = ownProfileAsync.asData?.value;
    final classesAsync = ref.watch(availableClassesProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final isGuardianViewer = isGuardianCalendarViewer(
      gate: gateData,
      ownProfile: ownProfile,
    );
    final isGuardianRole =
        gateData.role?.trim() == LoginFlowRoleIds.guardian;
    final isGuardianWaitingForChild =
        isGuardianRole && !gateData.hasConfirmedGuardianLink;
    final calendarFilters = ref.watch(calendarFiltersProvider);
    final effectiveCalendarProfile =
        ref.watch(effectiveCalendarProfileProvider).asData?.value;
    final calendarProfile =
        isGuardianViewer ? effectiveCalendarProfile : ownProfile;
    final calendarEditValues = resolveCalendarDefaultsEditValues(
      profile: calendarProfile,
      gate: isGuardianViewer ? null : gateData,
      filters: calendarFilters,
    );

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
      body: Stack(
        children: [
          CustomScrollView(
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
                    ownProfileAsync.when(
                      data: (profile) => SettingsProfileHeaderCard(
                        profile: profile,
                        onTap: _openProfile,
                      ),
                      loading: () => const _SettingsLoadingIsland(
                        message: 'Profil wird geladen...',
                      ),
                      error: (error, _) => _SettingsErrorIsland(
                        message: 'Profil konnte nicht geladen werden',
                        detail: error.toString(),
                      ),
                    ),
                    if (isGuardianRole) ...[
                      const SettingsSectionLabel(title: 'Familie', top: 22),
                      const GuardianChildProfileCards(),
                    ],
                    if (isGuardianWaitingForChild) ...[
                      const SettingsSectionLabel(title: 'Kalender', top: 22),
                      const _GuardianWaitingForChildIsland(),
                    ],
                    if (!isGuardianViewer && !isGuardianWaitingForChild)
                      ...ownProfileAsync.when(
                        data: (profile) => [
                          SettingsProfileSections(
                            profile: profile,
                            readOnly: _saving,
                            showCalendarDefaults: false,
                            onEditRole: () => _editChoiceField(
                              title: 'Rolle auswählen',
                              initialValue: profile?.role,
                              options: settingsRoleOptions,
                              onSave: (value) => _updateProfile(role: value),
                            ),
                            onEditClassName: () => _editChoiceField(
                              title: 'Klasse auswählen',
                              initialValue: profile?.className,
                              options: classesAsync.maybeWhen(
                                data: (classes) => classes,
                                orElse: () => const [],
                              ),
                              onSave: (value) =>
                                  _updateProfile(className: value),
                            ),
                            onEditSchoolTrack: () => _editChoiceField(
                              title: 'Schulzweig auswählen',
                              initialValue: schoolTrackDisplayLabel(
                                profile?.schoolTrack,
                              ),
                              options: settingsSchoolTrackOptions,
                              onSave: (value) =>
                                  _updateProfile(schoolTrack: value),
                            ),
                          ),
                        ],
                        loading: () => const [
                          SettingsSectionLabel(title: 'Schule', top: 22),
                          _SettingsLoadingIsland(
                            message: 'Profildaten werden geladen...',
                          ),
                        ],
                        error: (error, _) => [
                          const SettingsSectionLabel(title: 'Schule', top: 22),
                          _SettingsErrorIsland(
                            message: 'Profildaten konnten nicht geladen werden',
                            detail: error.toString(),
                          ),
                        ],
                      ),
                    if (!isGuardianWaitingForChild)
                      SettingsCalendarDefaultsSection(
                      readOnly: _saving,
                      onEditClassName: () => _editChoiceField(
                        title: 'Klasse auswählen',
                        initialValue: calendarEditValues.className,
                        options: classesAsync.maybeWhen(
                          data: (classes) => classes,
                          orElse: () => const [],
                        ),
                        onSave: (value) => _updateCalendarDefaults(
                          className: value,
                        ),
                      ),
                      onEditSchoolTrack: () => _editChoiceField(
                        title: 'Schulzweig auswählen',
                        initialValue: schoolTrackDisplayLabel(
                          calendarEditValues.schoolTrack,
                        ),
                        options: settingsSchoolTrackOptions,
                        onSave: (value) => _updateCalendarDefaults(
                          schoolTrack: value,
                        ),
                      ),
                      onEditChoir: () => _editChoirField(
                        initialChoirLabel:
                            choirDisplayLabel(calendarEditValues.choir),
                      ),
                      onEditVoice: () => _editChoiceField(
                        title: 'Stimme auswählen',
                        initialValue: calendarEditValues.voice,
                        options: settingsVoiceOptions,
                        onSave: (value) => _updateCalendarDefaults(
                          voice: value,
                        ),
                      ),
                      onEditDiet: () => _editChoiceField(
                        title: 'Ernährung auswählen',
                        initialValue:
                            dietDisplayLabel(calendarEditValues.diet),
                        options: settingsDietOptions,
                        onSave: (value) => _updateCalendarDefaults(
                          diet: value,
                        ),
                      ),
                    ),
                    const SettingsSectionLabel(title: 'Darstellung'),
                    SettingsIsland(
                      children: [
                        SettingsTile(
                          title: 'Design',
                          icon: SettingsIcons.appearance,
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SettingsScrollTopBlurOverlay(
              strength: _topBlurLinear,
              surfaceColor: bg,
            ),
          ),
        ],
      ),
    );
  }

  void _openProfile() {
    HapticFeedback.heavyImpact();
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => const SettingsProfilePage(),
      ),
    );
  }

  Future<void> _editChoirField({required String? initialChoirLabel}) async {
    HapticFeedback.heavyImpact();
    final value = await AppModalSheet.show<String>(
      context: context,
      showDragHandle: true,
      sheetAnimationStyle: kSettingsChoiceSheetMotion,
      builder: (context) {
        return AppModalSheetChrome(
          child: SettingsChoirCarouselSheet(
            initialChoirLabel: initialChoirLabel,
          ),
        );
      },
    );

    if (value == null || value == initialChoirLabel) return;
    await _updateCalendarDefaults(choir: value);
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
      sheetAnimationStyle: kSettingsChoiceSheetMotion,
      builder: (context) {
        return AppModalSheetChrome(
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

  Future<void> _updateCalendarDefaults({
    String? className,
    String? schoolTrack,
    String? voice,
    String? diet,
    String? choir,
  }) async {
    final gateData = ref.read(profileGateDataProvider);
    final ownProfile = ref.read(syncedProfileProvider).asData?.value;
    final isGuardianViewer = isGuardianCalendarViewer(
      gate: gateData,
      ownProfile: ownProfile,
    );

    if (isGuardianViewer) {
      await _updateActiveChildCalendarDefaults(
        className: className,
        schoolTrack: schoolTrack,
        voice: voice,
        diet: diet,
        choir: choir,
      );
      return;
    }

    await _updateProfile(
      className: className,
      schoolTrack: schoolTrack,
      voice: voice,
      diet: diet,
      choir: choir,
    );
  }

  Future<void> _updateActiveChildCalendarDefaults({
    String? className,
    String? schoolTrack,
    String? voice,
    String? diet,
    String? choir,
  }) async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      await updateGuardianActiveChildCalendarDefaults(
        ref,
        className: className,
        schoolTrack: schoolTrack,
        voice: voice,
        diet: diet,
        choir: choir,
      );
    } on SettingsProfileRepositoryException catch (e) {
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
            diet: diet,
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

class _GuardianWaitingForChildIsland extends StatelessWidget {
  const _GuardianWaitingForChildIsland();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SettingsIsland(
      children: [
        ListTile(
          leading: const Icon(Icons.info_outline_rounded, size: 22),
          title: const Text('Warten auf Kind-Bestätigung'),
          subtitle: Text(
            'Sobald dein Kind die Verknüpfung bestätigt hat, werden hier '
            'die Kalender-Standardwerte angezeigt.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
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
          leading: PhosphorIcon(SettingsIcons.error, size: 22),
          title: Text(message),
          subtitle: Text(detail, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
