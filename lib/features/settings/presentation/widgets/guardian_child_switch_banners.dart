import 'package:chronoapp/core/auth/auth_user_id_provider.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:chronoapp/features/login/data/guardian_link_repository.dart';
import 'package:chronoapp/features/login/domain/models/guardian_child_link.dart';
import 'package:chronoapp/features/login/presentation/providers/guardian_link_providers.dart';
import 'package:chronoapp/features/login/presentation/providers/profile_gate_provider.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_active_child_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const guardianChildSwitchBannerHeight = 64.0;
const guardianChildSwitchBannerGap = 8.0;

double guardianChildSwitchBannersBlockHeight(int inactiveCount) {
  if (inactiveCount <= 0) return 0;
  return guardianChildSwitchBannerGap +
      inactiveCount * guardianChildSwitchBannerHeight +
      (inactiveCount - 1) * guardianChildSwitchBannerGap;
}

List<GuardianChildLink> inactiveConfirmedGuardianLinks({
  required List<GuardianChildLink> links,
  required String guardianId,
  required String? activeChildId,
}) {
  return links
      .where(
        (link) =>
            link.guardianId == guardianId &&
            link.isConfirmed &&
            link.childId != activeChildId,
      )
      .toList(growable: false);
}

String guardianChildSwitchSubtitle(GuardianChildLink link) {
  final className = link.childClassName?.trim();
  if (className != null && className.isNotEmpty) {
    return 'Klasse $className · Kalender wechseln';
  }
  return 'Kalender wechseln';
}

class GuardianChildSwitchBanners extends ConsumerStatefulWidget {
  const GuardianChildSwitchBanners({super.key});

  @override
  ConsumerState<GuardianChildSwitchBanners> createState() =>
      _GuardianChildSwitchBannersState();
}

class _GuardianChildSwitchBannersState
    extends ConsumerState<GuardianChildSwitchBanners> {
  String? _switchingChildId;

  Future<void> _switchActiveChild(GuardianChildLink link) async {
    setState(() => _switchingChildId = link.childId);
    try {
      await switchGuardianActiveChild(ref, link);
      if (!mounted) return;
      showAppToast(
        context,
        'Aktives Kind: ${link.childDisplayName}',
        kind: AppToastKind.success,
      );
    } on GuardianLinkRepositoryException catch (e) {
      if (!mounted) return;
      showAppToast(context, e.message, kind: AppToastKind.error);
    } finally {
      if (mounted) setState(() => _switchingChildId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final linksAsync = ref.watch(guardianLinksProvider);
    final userId = ref.watch(authUserIdProvider).value;
    final activeChildId = ref.watch(profileGateProvider).data.activeChildId;

    if (userId == null) return const SizedBox.shrink();

    return linksAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (links) {
        final inactive = inactiveConfirmedGuardianLinks(
          links: links,
          guardianId: userId,
          activeChildId: activeChildId,
        );
        if (inactive.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            for (final link in inactive) ...[
              const SizedBox(height: guardianChildSwitchBannerGap),
              _GuardianChildSwitchBanner(
                link: link,
                switching: _switchingChildId == link.childId,
                enabled: _switchingChildId == null,
                onTap: () => _switchActiveChild(link),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _GuardianChildSwitchBanner extends StatelessWidget {
  const _GuardianChildSwitchBanner({
    required this.link,
    required this.switching,
    required this.enabled,
    required this.onTap,
  });

  final GuardianChildLink link;
  final bool switching;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initials = _childInitials(link);

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: scheme.surfaceContainer,
        shape: AppSquircle.shape(AppRadius.l),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: AppSquircle.shape(AppRadius.l),
          onTap: enabled && !switching
              ? () {
                  HapticFeedback.selectionClick();
                  onTap();
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  child: Text(
                    initials,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        link.childDisplayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        guardianChildSwitchSubtitle(link),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (switching)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.onSurfaceVariant,
                    ),
                  )
                else
                  PhosphorIcon(
                    PhosphorIcons.arrowsLeftRight(PhosphorIconsStyle.regular),
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _childInitials(GuardianChildLink link) {
  final firstName = (link.childFirstName ?? '').trim();
  final lastName = (link.childLastName ?? '').trim();
  final first = firstName.isEmpty ? '' : firstName.characters.first;
  final last = lastName.isEmpty ? '' : lastName.characters.first;
  final initials = '$first$last'.toUpperCase();
  return initials.isEmpty ? 'K' : initials;
}
