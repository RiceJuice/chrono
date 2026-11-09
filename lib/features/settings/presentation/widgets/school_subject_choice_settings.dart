import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/arts_subject.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../calendar/presentation/providers/filter/calendar/calendar_filters_provider.dart';
import '../../../calendar/presentation/providers/filter/search/search_filters_provider.dart';
import '../../../login/presentation/providers/auth_repository_provider.dart';
import '../../../login/presentation/providers/profile_gate_provider.dart';
import '../helpers/calendar_defaults_display.dart';
import '../helpers/guardian_calendar_viewer.dart';
import '../helpers/guardian_child_calendar_defaults_update.dart';
import '../helpers/guardian_child_permissions.dart';
import '../providers/effective_calendar_profile_provider.dart';
import '../providers/settings_profile_providers.dart';

/// Uses the same persisted profile choices as onboarding and the settings page.
class SchoolSubjectChoiceSettings extends ConsumerStatefulWidget {
  const SchoolSubjectChoiceSettings({super.key});

  @override
  ConsumerState<SchoolSubjectChoiceSettings> createState() =>
      _SchoolSubjectChoiceSettingsState();
}

class _SchoolSubjectChoiceSettingsState
    extends ConsumerState<SchoolSubjectChoiceSettings> {
  bool _saving = false;
  String? _error;

  Future<void> _save({String? languageSubject, String? artsSubject}) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final guardian = isGuardianCalendarViewer(
        gate: ref.read(profileGateDataProvider),
        ownProfile: ref.read(syncedProfileProvider).asData?.value,
      );
      if (guardian) {
        await updateGuardianActiveChildCalendarDefaults(
          ref,
          languageSubject: languageSubject,
          artsSubject: artsSubject,
        );
      } else {
        await ref
            .read(authRepositoryProvider)
            .updateProfile(
              languageSubject: languageSubject,
              artsSubject: artsSubject,
            );
        await ref.read(profileGateProvider).refresh();
        ref.invalidate(syncedProfileProvider);
        ref
            .read(calendarFiltersProvider.notifier)
            .applyProfileFilterChanges(
              languageSubject: languageSubject,
              artsSubject: artsSubject,
            );
        ref
            .read(searchFiltersProvider.notifier)
            .initializeFromCalendar(ref.read(calendarFiltersProvider));
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Die Fachwahl konnte nicht gespeichert werden. Bitte erneut versuchen.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gate = ref.watch(profileGateDataProvider);
    final own = ref.watch(syncedProfileProvider).asData?.value;
    final guardian = isGuardianCalendarViewer(gate: gate, ownProfile: own);
    if (guardian &&
        !ref.watch(activeGuardianChildPermissionsProvider).shareSchool) {
      return const SizedBox.shrink();
    }
    final profile = ref.watch(effectiveCalendarProfileProvider).asData?.value;
    final filters = ref.watch(calendarFiltersProvider);
    final values = resolveCalendarDefaultsEditValues(
      profile: profile,
      gate: guardian ? null : gate,
      filters: filters,
    );
    final classes = filters.classNames.isEmpty
        ? [values.className]
        : filters.classNames;
    final tracks = filters.schoolTracks.isEmpty
        ? [values.schoolTrack]
        : filters.schoolTracks;
    final language = classes.any(requiresLanguageSubject);
    final arts = classes.any(
      (className) =>
          tracks.any((track) => requiresArtsSubject(className, track)),
    );
    if (!language && !arts) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (language)
            _choice(
              'Französisch / Latein',
              values.languageSubject,
              languageSubjectOptions,
              (value) => _save(languageSubject: value),
            ),
          if (arts)
            _choice(
              'Musik / Kunst',
              values.artsSubject,
              artsSubjectOptions,
              (value) => _save(artsSubject: value),
            ),
          const SizedBox(height: 4),
          Text(
            'Die Fachwahl wird auch in deinem Profil und Stundenplan übernommen.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (_saving) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }

  Widget _choice(
    String title,
    String? value,
    List<String> options,
    ValueChanged<String> onSelected,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in options)
                ChoiceChip(
                  label: Text(option),
                  selected: value == option,
                  showCheckmark: false,
                  selectedColor: scheme.primary,
                  backgroundColor: scheme.surfaceContainerHighest,
                  disabledColor: value == option
                      ? scheme.primary
                      : scheme.surfaceContainerHighest,
                  side: BorderSide.none,
                  labelStyle: TextStyle(
                    color: value == option
                        ? scheme.onPrimary
                        : scheme.onSurface,
                  ),
                  onSelected: _saving
                      ? null
                      : (_) {
                          if (value == option) return;
                          AppHaptics.selection();
                          onSelected(option);
                        },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
