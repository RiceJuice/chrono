import 'dart:async';

import 'package:chronoapp/core/auth/auth_user_id_provider.dart';
import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:chronoapp/features/login/domain/models/guardian_child_link.dart';
import 'package:chronoapp/features/login/presentation/pages/select_child/select_child_page.dart';
import 'package:chronoapp/features/login/presentation/providers/guardian_link_providers.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_child_profile_display.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_own_links.dart';
import 'package:chronoapp/features/settings/presentation/helpers/settings_icons.dart';
import 'package:chronoapp/features/settings/presentation/pages/settings_linked_child_page.dart';
import 'package:chronoapp/features/settings/presentation/providers/effective_calendar_profile_provider.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_island.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_profile_header_card.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class GuardianChildProfileCards extends ConsumerWidget {
  const GuardianChildProfileCards({super.key});

  Future<void> _openAddChildSheet(BuildContext context) async {
    await AppModalSheet.show<void>(
      context: context,
      builder: (context) => const _AddChildSheet(),
    );
  }

  void _openChildProfile(BuildContext context, GuardianChildLink link) {
    HapticFeedback.heavyImpact();
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => SettingsLinkedChildPage(link: link),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(guardianLinksProvider);
    final userId = ref.watch(authUserIdProvider).value;

    if (userId == null) return const SizedBox.shrink();

    return linksAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsIsland(
            children: [
              SettingsTile(
                title: 'Kind hinzufügen',
                icon: SettingsIcons.addChild,
                trailing: PhosphorIcon(
                  PhosphorIcons.plus(PhosphorIconsStyle.bold),
                  size: 20,
                ),
                onTap: () => unawaited(_openAddChildSheet(context)),
              ),
            ],
          ),
        ],
      ),
      data: (links) {
        final ownLinks = mergeGuardianOwnLinks(
          streamLinks: links,
          remoteLinks: const [],
          guardianId: userId,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final link in ownLinks) ...[
              const SizedBox(height: 8),
              _GuardianChildProfileCard(
                link: link,
                onTap: guardianChildCardIsTappable(link)
                    ? () => _openChildProfile(context, link)
                    : null,
              ),
            ],
            const SizedBox(height: 12),
            SettingsIsland(
              children: [
                SettingsTile(
                  title: 'Kind hinzufügen',
                  icon: SettingsIcons.addChild,
                  trailing: PhosphorIcon(
                    PhosphorIcons.plus(PhosphorIconsStyle.bold),
                    size: 20,
                  ),
                  onTap: () => unawaited(_openAddChildSheet(context)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _GuardianChildProfileCard extends ConsumerWidget {
  const _GuardianChildProfileCard({
    required this.link,
    required this.onTap,
  });

  final GuardianChildLink link;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(linkedChildProfileProvider(link.childId));

    return profileAsync.when(
      data: (loaded) => SettingsProfileHeaderCard(
        profile: guardianChildProfileSnapshot(
          link: link,
          loaded: loaded,
        ),
        onTap: onTap,
        compact: true,
      ),
      loading: () => SettingsProfileHeaderCard(
        profile: guardianChildProfileSnapshot(link: link, loaded: null),
        compact: true,
      ),
      error: (_, _) => SettingsProfileHeaderCard(
        profile: guardianChildProfileSnapshot(link: link, loaded: null),
        onTap: onTap,
        compact: true,
      ),
    );
  }
}

class _AddChildSheet extends StatelessWidget {
  const _AddChildSheet();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ),
          Expanded(
            child: SelectChildPage(
              embeddedInSettings: true,
              onLinkRequested: () {},
            ),
          ),
        ],
      ),
    );
  }
}
