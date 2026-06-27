import 'package:flutter/material.dart';

import '../../domain/models/guardian_child_link.dart';
import '../../domain/models/guardian_child_share_permissions.dart';

class GuardianLinkConfirmResult {
  const GuardianLinkConfirmResult({
    required this.accept,
    required this.sharePermissions,
  });

  final bool? accept;
  final GuardianChildSharePermissions sharePermissions;
}

Future<GuardianLinkConfirmResult?> showGuardianLinkConfirmDialog(
  BuildContext context, {
  required GuardianChildLink link,
  String? guardianNameOverride,
}) {
  final guardianName = _resolveGuardianName(link, guardianNameOverride);

  return showDialog<GuardianLinkConfirmResult>(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: GuardianLinkConfirmWalkthrough(
          guardianName: guardianName,
        ),
      ),
    ),
  );
}

String _resolveGuardianName(
  GuardianChildLink link,
  String? guardianNameOverride,
) {
  final override = guardianNameOverride?.trim();
  if (override != null && override.isNotEmpty) return override;
  return link.guardianDisplayName;
}

class GuardianLinkConfirmWalkthrough extends StatefulWidget {
  const GuardianLinkConfirmWalkthrough({
    super.key,
    required this.guardianName,
  });

  final String guardianName;

  @override
  State<GuardianLinkConfirmWalkthrough> createState() =>
      _GuardianLinkConfirmWalkthroughState();
}

class _GuardianLinkConfirmWalkthroughState
    extends State<GuardianLinkConfirmWalkthrough> {
  static const _stepCount = 3;

  int _step = 0;
  GuardianChildSharePermissions _permissions =
      GuardianChildSharePermissions.minimal;

  void _nextStep() {
    if (_step >= _stepCount - 1) return;
    setState(() => _step++);
  }

  void _previousStep() {
    if (_step <= 0) return;
    setState(() => _step--);
  }

  void _togglePermission(String key, bool value) {
    setState(() {
      _permissions = switch (key) {
        GuardianChildSharePermissions.schoolKey =>
          _permissions.copyWith(shareSchool: value),
        GuardianChildSharePermissions.mealKey =>
          _permissions.copyWith(shareMeal: value),
        GuardianChildSharePermissions.choirKey =>
          _permissions.copyWith(shareChoir: value),
        GuardianChildSharePermissions.homeworkKey =>
          _permissions.copyWith(shareHomework: value),
        _ => _permissions.copyWith(
            extra: {..._permissions.extra, key: value},
          ),
      };
    });
  }

  void _finish(bool accept) {
    Navigator.of(context).pop(
      GuardianLinkConfirmResult(
        accept: accept,
        sharePermissions: _permissions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepIndicator(currentStep: _step, stepCount: _stepCount),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: switch (_step) {
              0 => _RequestStep(
                  key: const ValueKey('step-0'),
                  guardianName: widget.guardianName,
                  scheme: scheme,
                  theme: theme,
                ),
              1 => _PrivacyStep(
                  key: const ValueKey('step-1'),
                  permissions: _permissions,
                  onToggle: _togglePermission,
                  theme: theme,
                  scheme: scheme,
                ),
              _ => _ReviewStep(
                  key: const ValueKey('step-2'),
                  guardianName: widget.guardianName,
                  permissions: _permissions,
                  theme: theme,
                  scheme: scheme,
                ),
            },
          ),
          const SizedBox(height: 28),
          if (_step < _stepCount - 1) ...[
            FilledButton(
              onPressed: _nextStep,
              child: const Text('Weiter'),
            ),
            if (_step > 0) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _previousStep,
                child: const Text('Zurück'),
              ),
            ],
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _finish(false),
                    child: const Text('Ablehnen'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _finish(true),
                    child: const Text('Verknüpfen'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _previousStep,
              child: const Text('Zurück'),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.currentStep,
    required this.stepCount,
  });

  final int currentStep;
  final int stepCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(stepCount, (index) {
            final active = index == currentStep;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Text(
          'Schritt ${currentStep + 1} von $stepCount',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }
}

class _RequestStep extends StatelessWidget {
  const _RequestStep({
    super.key,
    required this.guardianName,
    required this.scheme,
    required this.theme,
  });

  final String guardianName;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.family_restroom_rounded,
            size: 34,
            color: scheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Eltern-Verknüpfung',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          '$guardianName möchte sich als Elternteil mit dir verknüpfen.',
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Im nächsten Schritt entscheidest du, was dein Elternteil sehen darf.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.65),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _PrivacyStep extends StatelessWidget {
  const _PrivacyStep({
    super.key,
    required this.permissions,
    required this.onToggle,
    required this.theme,
    required this.scheme,
  });

  final GuardianChildSharePermissions permissions;
  final void Function(String key, bool value) onToggle;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Was darf geteilt werden?',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Standardmäßig ist nichts freigegeben. Du kannst das später in den '
          'Einstellungen ändern.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.65),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        for (final option in guardianSharePermissionOptions) ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(option.label),
            subtitle: Text(_permissionSubtitle(option.key)),
            value: permissions.isEnabled(option.key),
            onChanged: (value) => onToggle(option.key, value),
          ),
        ],
      ],
    );
  }

  String _permissionSubtitle(String key) {
    return switch (key) {
      GuardianChildSharePermissions.schoolKey =>
        'Stundenplan und schulische Termine',
      GuardianChildSharePermissions.mealKey => 'Mensa und Speiseplan',
      GuardianChildSharePermissions.choirKey => 'Chor-Termine und Proben',
      GuardianChildSharePermissions.homeworkKey => 'Deine Aufgabenliste',
      _ => '',
    };
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    super.key,
    required this.guardianName,
    required this.permissions,
    required this.theme,
    required this.scheme,
  });

  final String guardianName;
  final GuardianChildSharePermissions permissions;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final enabledLabels = guardianSharePermissionOptions
        .where((option) => permissions.isEnabled(option.key))
        .map((option) => option.label)
        .toList(growable: false);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Zusammenfassung',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          '$guardianName erhält nach der Verknüpfung Zugriff auf:',
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        if (enabledLabels.isEmpty)
          Text(
            'Nichts — du teilst vorerst keine Bereiche.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.65),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          )
        else
          ...enabledLabels.map(
            (label) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(label, style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
