import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:flutter/material.dart';

import '../state/login_flow_draft.dart';

/// Klassen-Multi-Select vor der Kind-Suche (Einstellungen).
Future<List<String>?> showGuardianChildClassesPicker({
  required BuildContext context,
  required List<String> classOptions,
  List<String>? initialSelection,
}) {
  return AppModalSheet.show<List<String>>(
    context: context,
    builder: (context) => _GuardianChildClassesPickerSheet(
      classOptions: classOptions,
      initialSelection: initialSelection ?? const [],
    ),
  );
}

class _GuardianChildClassesPickerSheet extends StatefulWidget {
  const _GuardianChildClassesPickerSheet({
    required this.classOptions,
    required this.initialSelection,
  });

  final List<String> classOptions;
  final List<String> initialSelection;

  @override
  State<_GuardianChildClassesPickerSheet> createState() =>
      _GuardianChildClassesPickerSheetState();
}

class _GuardianChildClassesPickerSheetState
    extends State<_GuardianChildClassesPickerSheet> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.initialSelection);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Klassen wählen',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Wähle die Klassen, in denen deine Kinder sind. Die Suche '
              'zeigt nur Schüler aus diesen Klassen.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (widget.classOptions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Keine Klassen verfügbar. Bitte später erneut versuchen.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final className in widget.classOptions)
                      CheckboxListTile(
                        value: _selected.contains(className),
                        title: Text(className),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selected.add(className);
                            } else {
                              _selected.remove(className);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _selected.isEmpty
                  ? null
                  : () {
                      final sorted = _selected.toList()..sort();
                      LoginFlowDraft.instance.guardianChildClasses = sorted;
                      Navigator.of(context).pop(sorted);
                    },
              child: const Text('Weiter zur Suche'),
            ),
          ],
        ),
      ),
    );
  }
}
