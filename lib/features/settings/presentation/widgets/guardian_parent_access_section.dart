import 'dart:async';

import 'package:chronoapp/core/auth/auth_user_id_provider.dart';
import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:chronoapp/features/login/data/guardian_link_repository.dart';
import 'package:chronoapp/features/login/domain/models/guardian_child_link.dart';
import 'package:chronoapp/features/login/domain/models/guardian_child_share_permissions.dart';
import 'package:chronoapp/features/login/presentation/providers/guardian_link_providers.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_island.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_section_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Einstellungen für Schüler: Freigaben pro bestätigtem Elternteil.
class GuardianParentAccessSection extends ConsumerWidget {
  const GuardianParentAccessSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authUserIdProvider).value;
    if (userId == null) return const SizedBox.shrink();

    final linksAsync = ref.watch(guardianLinksProvider);
    return linksAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (links) {
        final confirmed = links
            .where((link) => link.isConfirmed && link.childId == userId)
            .toList(growable: false);
        if (confirmed.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SettingsSectionLabel(title: 'Elternteil', top: 22),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Was deine Eltern sehen dürfen',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
              ),
            ),
            for (final link in confirmed) ...[
              if (link != confirmed.first) const SizedBox(height: 8),
              _GuardianAccessCard(link: link),
            ],
          ],
        );
      },
    );
  }
}

class _GuardianAccessCard extends ConsumerStatefulWidget {
  const _GuardianAccessCard({required this.link});

  final GuardianChildLink link;

  @override
  ConsumerState<_GuardianAccessCard> createState() =>
      _GuardianAccessCardState();
}

class _GuardianAccessCardState extends ConsumerState<_GuardianAccessCard> {
  late GuardianChildSharePermissions _permissions = widget.link.sharePermissions;
  bool _saving = false;

  @override
  void didUpdateWidget(covariant _GuardianAccessCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.link.id != widget.link.id ||
        oldWidget.link.sharePermissions != widget.link.sharePermissions) {
      _permissions = widget.link.sharePermissions;
    }
  }

  Future<void> _save(GuardianChildSharePermissions next) async {
    setState(() {
      _permissions = next;
      _saving = true;
    });
    try {
      await ref.read(guardianLinkRepositoryProvider).updateSharePermissions(
            linkId: widget.link.id,
            sharePermissions: next,
          );
      if (!mounted) return;
    } on GuardianLinkRepositoryException catch (e) {
      if (!mounted) return;
      setState(() => _permissions = widget.link.sharePermissions);
      showAppToast(context, e.message, kind: AppToastKind.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toggle(String key, bool value) {
    if (_saving) return;
    final next = switch (key) {
      GuardianChildSharePermissions.schoolKey =>
        _permissions.copyWith(shareSchool: value),
      GuardianChildSharePermissions.mealKey =>
        _permissions.copyWith(shareMeal: value),
      GuardianChildSharePermissions.choirKey =>
        _permissions.copyWith(shareChoir: value),
      GuardianChildSharePermissions.homeworkKey =>
        _permissions.copyWith(shareHomework: value),
      _ => _permissions.copyWith(extra: {..._permissions.extra, key: value}),
    };
    unawaited(_save(next));
  }

  @override
  Widget build(BuildContext context) {
    return SettingsIsland(
      children: [
        ListTile(
          title: Text(widget.link.guardianDisplayName),
        ),
        for (final option in guardianSharePermissionOptions)
          SwitchListTile(
            title: Text(option.label),
            value: _permissions.isEnabled(option.key),
            onChanged: _saving ? null : (value) => _toggle(option.key, value),
          ),
      ],
    );
  }
}
