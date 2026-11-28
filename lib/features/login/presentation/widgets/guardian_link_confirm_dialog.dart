import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/widgets/app_modal_sheet.dart';
import '../../../../core/theme/theme_tokens.dart';
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
  required Future<void> Function(GuardianLinkConfirmResult) onSubmit,
  ValueListenable<bool>? sessionValid,
}) => AppModalSheet.show<GuardianLinkConfirmResult>(
  context: context,
  isDismissible: false,
  enableDrag: false,
  sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
      ? AnimationStyle.noAnimation
      : null,
  builder: (context) => AppModalSheetChrome(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * .9,
    ),
    child: GuardianLinkConfirmWalkthrough(
      guardianName: link.guardianDisplayName,
      onSubmit: onSubmit,
      sessionValid: sessionValid,
    ),
  ),
);

class GuardianLinkConfirmWalkthrough extends StatefulWidget {
  const GuardianLinkConfirmWalkthrough({
    super.key,
    required this.guardianName,
    required this.onSubmit,
    this.sessionValid,
  });
  final String guardianName;
  final Future<void> Function(GuardianLinkConfirmResult) onSubmit;
  final ValueListenable<bool>? sessionValid;
  @override
  State<GuardianLinkConfirmWalkthrough> createState() =>
      _GuardianLinkConfirmWalkthroughState();
}

class _GuardianLinkConfirmWalkthroughState
    extends State<GuardianLinkConfirmWalkthrough> {
  GuardianChildSharePermissions _permissions =
      GuardianChildSharePermissions.minimal;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    widget.sessionValid?.addListener(_sessionChanged);
  }

  @override
  void dispose() {
    widget.sessionValid?.removeListener(_sessionChanged);
    super.dispose();
  }

  void _sessionChanged() {
    if (widget.sessionValid?.value == false && mounted) {
      final route = ModalRoute.of(context);
      if (route != null) Navigator.of(context).removeRoute(route);
    }
  }

  Future<void> _submit(bool accept) async {
    if (_busy || widget.sessionValid?.value == false) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = GuardianLinkConfirmResult(
      accept: accept,
      sharePermissions: _permissions,
    );
    try {
      await widget.onSubmit(result);
      if (mounted && widget.sessionValid?.value != false) {
        Navigator.of(context).pop(result);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Die Antwort wurde nicht bestätigt. Deine Auswahl bleibt erhalten. Bitte erneut versuchen oder die Anfrage später neu öffnen.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toggle(String key, bool value) {
    setState(
      () => _permissions = GuardianChildSharePermissions.fromJson({
        ..._permissions.toJson(),
        key: value,
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = guardianSharePermissionOptions
        .where((o) => _permissions.isEnabled(o.key))
        .map((o) => o.label)
        .join(', ');
    return PopScope(
      canPop: !_busy,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Verknüpfungsanfrage',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${widget.guardianName} möchte sich mit dir verknüpfen.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Prüfe, ob du diese Person kennst. Du entscheidest, was sie sehen darf. Du kannst Freigaben später ändern oder die Verbindung trennen.',
              ),
              const SizedBox(height: 20),
              Text(
                'Was möchtest du teilen?',
                style: theme.textTheme.titleMedium,
              ),
              for (final option in guardianSharePermissionOptions)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(option.label),
                  value: _permissions.isEnabled(option.key),
                  onChanged: _busy
                      ? null
                      : (value) => _toggle(option.key, value),
                ),
              const SizedBox(height: 12),
              Text(
                selected.isEmpty
                    ? 'Verbindung bestätigen, derzeit keine Inhalte teilen.'
                    : 'Du teilst: $selected.',
                style: theme.textTheme.bodyMedium,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : () => _submit(true),
                child: Text(_busy ? 'Wird gespeichert …' : 'Verknüpfen'),
              ),
              TextButton(
                onPressed: _busy ? null : () => _submit(false),
                child: const Text('Nicht verknüpfen'),
              ),
              TextButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
                child: const Text('Später'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
