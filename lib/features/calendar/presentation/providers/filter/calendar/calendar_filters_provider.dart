import 'package:chronoapp/core/startup/calendar_filter_startup_state.dart';
import 'package:chronoapp/features/login/presentation/providers/profile_gate_provider.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_calendar_viewer.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_child_permissions.dart';
import 'package:chronoapp/features/settings/presentation/providers/settings_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as fr;

import '../../../../domain/filter/calendar_filter_defaults.dart';
import '../../../../domain/filter/calendar_filter_text.dart';
import '../../../../../settings/data/models/profile_snapshot.dart';
import 'calendar_filters_state.dart';
import '../shared/calendar_filters_notifier_base.dart';

class CalendarFiltersNotifier extends CalendarFiltersNotifierBase {
  @override
  CalendarFiltersState build() {
    final bootstrapped = CalendarFilterStartupState.consume();
    if (bootstrapped != null) {
      return bootstrapped;
    }
    return super.build();
  }

  void initializeFromProfile(ProfileSnapshot? profile) {
    final defaults = calendarFiltersStateFromProfileFields(
      choir: profile?.choir,
      voice: profile?.voice,
      className: profile?.className,
      schoolTrack: profile?.schoolTrack,
      diet: profile?.diet,
    );
    initializeDefaults(
      choirs: defaults.choirs,
      voices: defaults.voices,
      classNames: defaults.classNames,
      schoolTracks: defaults.schoolTracks,
      diets: defaults.diets,
    );
  }

  /// Ersetzt aktive und Default-Filter vollständig — z. B. beim Kindwechsel
  /// für Elternteile, damit keine manuellen Overrides vom vorherigen Kind bleiben.
  void replaceFromProfile(ProfileSnapshot? profile) {
    final next = calendarFiltersStateFromProfileFields(
      choir: profile?.choir,
      voice: profile?.voice,
      className: profile?.className,
      schoolTrack: profile?.schoolTrack,
      diet: profile?.diet,
    );
    state = next;
  }

  /// Uebernimmt Profil-Aenderungen sofort in aktive und Default-Filter.
  /// So sind Kalender- und Suchfilter direkt konsistent mit den Einstellungen.
  void applyProfileFilterChanges({
    String? choir,
    String? voice,
    String? className,
    String? schoolTrack,
    String? diet,
  }) {
    final nextChoirs = choir == null
        ? state.choirs
        : normalizedCalendarFilterList([choir]);
    final nextVoices = voice == null
        ? state.voices
        : normalizedCalendarFilterList([voice]);
    final nextClassNames = className == null
        ? state.classNames
        : normalizedCalendarFilterList([className]);
    final nextSchoolTracks = schoolTrack == null
        ? state.schoolTracks
        : normalizedCalendarFilterList([schoolTrack]);
    final nextDiets = diet == null
        ? state.diets
        : normalizedCalendarFilterList([diet]);

    state = state.copyWith(
      choirs: nextChoirs,
      voices: nextVoices,
      classNames: nextClassNames,
      schoolTracks: nextSchoolTracks,
      diets: nextDiets,
      defaultChoirs: choir == null ? state.defaultChoirs : nextChoirs,
      defaultVoices: voice == null ? state.defaultVoices : nextVoices,
      defaultClassNames: className == null ? state.defaultClassNames : nextClassNames,
      defaultSchoolTracks: schoolTrack == null
          ? state.defaultSchoolTracks
          : nextSchoolTracks,
      defaultDiets: diet == null ? state.defaultDiets : nextDiets,
      hasInitializedDefaults: true,
      isChoirExplicit: choir == null ? state.isChoirExplicit : false,
      isVoiceExplicit: voice == null ? state.isVoiceExplicit : false,
      isClassNameExplicit: className == null ? state.isClassNameExplicit : false,
      isSchoolTrackExplicit: schoolTrack == null ? state.isSchoolTrackExplicit : false,
      isDietExplicit: diet == null ? state.isDietExplicit : false,
      hasUserOverrides: false,
    );
  }

  @override
  void setCalendarVisibility(CalendarVisibility calendar, bool isVisible) {
    if (!_mayChangeCalendarVisibility(calendar, isVisible)) return;
    super.setCalendarVisibility(calendar, isVisible);
  }

  @override
  void resetToDefaults() {
    super.resetToDefaults();
    _reapplyGuardianSharePermissions();
  }

  bool _mayChangeCalendarVisibility(
    CalendarVisibility calendar,
    bool isVisible,
  ) {
    final gate = ref.read(profileGateDataProvider);
    final ownProfile = ref.read(syncedProfileProvider).asData?.value;
    final isGuardianViewer = isGuardianCalendarViewer(
      gate: gate,
      ownProfile: ownProfile,
    );
    if (!isGuardianViewer) return true;

    final permissions = ref.read(activeGuardianChildPermissionsProvider);
    if (!guardianCalendarTypeConfigurable(
      isGuardianViewer: true,
      permissions: permissions,
      calendar: calendar,
    )) {
      return false;
    }
    if (!isVisible) return true;
    return guardianMayEnableCalendarType(
      isGuardianViewer: true,
      permissions: permissions,
      calendar: calendar,
    );
  }

  void _reapplyGuardianSharePermissions() {
    final gate = ref.read(profileGateDataProvider);
    final ownProfile = ref.read(syncedProfileProvider).asData?.value;
    if (!isGuardianCalendarViewer(gate: gate, ownProfile: ownProfile)) return;

    final permissions = ref.read(activeGuardianChildPermissionsProvider);
    applyGuardianSharePermissions(
      shareSchool: permissions.shareSchool,
      shareMeal: permissions.shareMeal,
      shareChoir: permissions.shareChoir,
    );
  }
}

final calendarFiltersProvider =
    fr.NotifierProvider<CalendarFiltersNotifier, CalendarFiltersState>(
      CalendarFiltersNotifier.new,
    );
