import 'package:chronoapp/features/login/domain/models/guardian_child_share_permissions.dart';
import 'package:chronoapp/features/login/presentation/providers/profile_gate_provider.dart';
import 'package:chronoapp/features/settings/data/models/profile_snapshot.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_calendar_filter_sync_helper.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_child_permissions.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_calendar_viewer.dart';
import 'package:chronoapp/features/settings/presentation/providers/effective_calendar_profile_provider.dart';
import 'package:chronoapp/features/settings/presentation/providers/settings_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hält Kalender- und Suchfilter für Elternteile am Profil des aktiven Kindes.
class GuardianCalendarFilterSync extends ConsumerStatefulWidget {
  const GuardianCalendarFilterSync({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<GuardianCalendarFilterSync> createState() =>
      _GuardianCalendarFilterSyncState();
}

class _GuardianCalendarFilterSyncState
    extends ConsumerState<GuardianCalendarFilterSync> {
  String? _lastSyncedKey;

  void _scheduleSync(
    ProfileSnapshot? profile,
    String? activeChildId,
    GuardianChildSharePermissions permissions,
  ) {
    final key = [
      guardianCalendarFilterSyncKey(activeChildId, profile),
      permissions.shareSchool,
      permissions.shareMeal,
      permissions.shareChoir,
      permissions.shareHomework,
    ].join('|');
    if (key == _lastSyncedKey) return;
    _lastSyncedKey = key;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      syncGuardianCalendarFilters(
        ref,
        profile,
        sharePermissions: permissions,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final gate = ref.watch(profileGateDataProvider);
    final ownProfile = ref.watch(syncedProfileProvider).asData?.value;
    final isGuardianViewer = isGuardianCalendarViewer(
      gate: gate,
      ownProfile: ownProfile,
    );

    if (isGuardianViewer) {
      final activeChildId = gate.activeChildId;
      final permissions = ref.watch(activeGuardianChildPermissionsProvider);
      ref.watch(effectiveCalendarProfileProvider).whenData((profile) {
        _scheduleSync(profile, activeChildId, permissions);
      });
    }

    return widget.child;
  }
}
