import 'package:chronoapp/core/auth/auth_user_id_provider.dart';
import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:chronoapp/features/login/data/guardian_link_repository.dart';
import 'package:chronoapp/features/login/domain/models/guardian_child_link.dart';
import 'package:chronoapp/features/login/presentation/pages/select_child/select_child_page.dart';
import 'package:chronoapp/features/login/presentation/providers/guardian_link_providers.dart';
import 'package:chronoapp/features/login/presentation/providers/klassen_provider.dart';
import 'package:chronoapp/features/login/presentation/providers/profile_gate_provider.dart';
import 'package:chronoapp/features/login/presentation/widgets/guardian_child_classes_picker_sheet.dart';
import 'package:chronoapp/features/settings/presentation/helpers/guardian_active_child_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GuardianChildrenSection extends ConsumerStatefulWidget {
  const GuardianChildrenSection({super.key});

  @override
  ConsumerState<GuardianChildrenSection> createState() =>
      _GuardianChildrenSectionState();
}

class _GuardianChildrenSectionState
    extends ConsumerState<GuardianChildrenSection> {
  bool _switching = false;

  Future<void> _switchActiveChild(GuardianChildLink link) async {
    setState(() => _switching = true);
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
      if (mounted) setState(() => _switching = false);
    }
  }

  Future<void> _openAddChildSheet() async {
    final classOptions =
        ref.read(availableClassesProvider).asData?.value ?? const <String>[];
    final selectedClasses = await showGuardianChildClassesPicker(
      context: context,
      classOptions: classOptions,
    );
    if (!mounted || selectedClasses == null || selectedClasses.isEmpty) return;

    await AppModalSheet.show<void>(
      context: context,
      builder: (context) => _AddChildSheet(classNames: selectedClasses),
    );
  }

  @override
  Widget build(BuildContext context) {
    final linksAsync = ref.watch(guardianLinksProvider);
    final userId = ref.watch(authUserIdProvider).value;
    final activeChildId = ref.read(profileGateProvider).data.activeChildId;
    final theme = Theme.of(context);

    if (userId == null) return const SizedBox.shrink();

    return linksAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (links) {
        final ownLinks = links.where((l) => l.guardianId == userId).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Meine Kinder',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ),
            if (ownLinks.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Noch keine Kinder verknüpft.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ...ownLinks.map((link) {
              final isActive =
                  link.isConfirmed && link.childId == activeChildId;
              final statusLabel = switch (link.status) {
                GuardianLinkStatus.pending => 'Ausstehend',
                GuardianLinkStatus.confirmed =>
                  isActive ? 'Aktiv' : 'Bestätigt',
                GuardianLinkStatus.rejected => 'Abgelehnt',
                _ => link.status,
              };

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(link.childDisplayName),
                subtitle: Text(statusLabel),
                trailing: link.isConfirmed
                    ? (_switching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            isActive
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: isActive
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                          ))
                    : null,
                onTap: link.isConfirmed && !isActive && !_switching
                    ? () => _switchActiveChild(link)
                    : null,
              );
            }),
            TextButton(
              onPressed: _openAddChildSheet,
              child: const Text('Weiteres Kind hinzufügen'),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Du kannst jederzeit weitere Kinder hinzufügen.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AddChildSheet extends StatelessWidget {
  const _AddChildSheet({required this.classNames});

  final List<String> classNames;

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
              onLinkRequested: () {},
              classNamesOverride: classNames,
            ),
          ),
        ],
      ),
    );
  }
}
