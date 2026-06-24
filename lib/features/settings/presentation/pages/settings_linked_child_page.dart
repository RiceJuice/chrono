import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/core/widgets/app_glass_back_button.dart';
import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:chronoapp/core/widgets/main_shell_scaffold.dart';
import 'package:chronoapp/features/login/data/guardian_link_repository.dart';
import 'package:chronoapp/features/login/domain/models/guardian_child_link.dart';
import 'package:chronoapp/features/login/presentation/providers/profile_gate_provider.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_active_child_switch.dart';
import 'package:chronoapp/features/settings/presentation/providers/effective_calendar_profile_provider.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_profile_header_card.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_profile_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsLinkedChildPage extends ConsumerStatefulWidget {
  const SettingsLinkedChildPage({
    super.key,
    required this.link,
  });

  final GuardianChildLink link;

  @override
  ConsumerState<SettingsLinkedChildPage> createState() =>
      _SettingsLinkedChildPageState();
}

class _SettingsLinkedChildPageState extends ConsumerState<SettingsLinkedChildPage> {
  bool _switching = false;

  Future<void> _switchActiveChild() async {
    setState(() => _switching = true);
    try {
      await switchGuardianActiveChild(ref, widget.link);
      if (!mounted) return;
      showAppToast(
        context,
        'Aktives Kind: ${widget.link.childDisplayName}',
        kind: AppToastKind.success,
      );
    } on GuardianLinkRepositoryException catch (e) {
      if (!mounted) return;
      showAppToast(context, e.message, kind: AppToastKind.error);
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(linkedChildProfileProvider(widget.link.childId));
    final activeChildId = ref.watch(profileGateDataProvider).activeChildId;
    final isActive = widget.link.childId == activeChildId;
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
          widget.link.childDisplayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
            if (widget.link.isConfirmed) ...[
              const SizedBox(height: 18),
              _CalendarSwitchCard(
                isActive: isActive,
                switching: _switching,
                onTap: isActive || _switching ? null : _switchActiveChild,
              ),
            ],
            SettingsProfileSections(
              profile: profile,
              readOnly: true,
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
}

class _CalendarSwitchCard extends StatelessWidget {
  const _CalendarSwitchCard({
    required this.isActive,
    required this.switching,
    required this.onTap,
  });

  final bool isActive;
  final bool switching;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tappable = onTap != null;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? 'Kalender aktiv' : 'Kalender anzeigen',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  isActive
                      ? 'Du siehst aktuell den Kalender dieses Kindes.'
                      : 'Kalender und Termine auf dieses Kind umschalten.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (switching)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.primary,
              ),
            )
          else if (isActive)
            Icon(Icons.check_circle, color: scheme.primary, size: 22)
          else
            Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ],
      ),
    );

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: scheme.surfaceContainerHigh,
        shape: AppSquircle.shape(AppRadius.xl),
      ),
      child: tappable
          ? Material(
              type: MaterialType.transparency,
              child: InkWell(
                customBorder: AppSquircle.shape(AppRadius.xl),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
                child: content,
              ),
            )
          : content,
    );
  }
}
