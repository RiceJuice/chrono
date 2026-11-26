import 'package:flutter/material.dart';

import '../../../../../core/haptics/app_haptics.dart';
import '../../../../../core/widgets/app_modal_sheet.dart';

/// Keeps the settings compact, regardless of how many classes are available.
class CalendarClassFilterSection extends StatelessWidget {
  const CalendarClassFilterSection({
    super.key,
    required this.selectedValues,
    required this.options,
    required this.onToggle,
    required this.onClear,
  });

  final List<String> selectedValues;
  final List<String> options;
  final ValueChanged<String> onToggle;
  final VoidCallback onClear;

  Future<void> _open(BuildContext context) async {
    AppHaptics.selection();
    final next = await AppModalSheet.show<List<String>>(
      context: context,
      useSafeArea: true,
      sheetAnimationStyle: kSettingsChoiceSheetMotion,
      builder: (_) => _ClassPicker(
        options: {...options, ...selectedValues}.toList(),
        selected: selectedValues,
      ),
    );
    if (next == null || !context.mounted) return;
    if (next.length == selectedValues.length &&
        next.toSet().containsAll(selectedValues)) {
      return;
    }
    onClear();
    for (final value in next) {
      onToggle(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = selectedValues.isEmpty
        ? 'Alle Klassen'
        : selectedValues.map((value) => value.toUpperCase()).join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Klasse', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Material(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            leading: Icon(
              Icons.groups_outlined,
              color: theme.colorScheme.primary,
            ),
            title: Text(summary, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: const Text('Klassen auswählen'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _open(context),
          ),
        ),
      ],
    );
  }
}

class _ClassPicker extends StatefulWidget {
  const _ClassPicker({required this.options, required this.selected});

  final List<String> options;
  final List<String> selected;

  @override
  State<_ClassPicker> createState() => _ClassPickerState();
}

class _ClassPickerState extends State<_ClassPicker> {
  late final Set<String> _selected = widget.selected.toSet();
  late final List<String> _options = [...widget.options]
    ..sort((a, b) {
      int? grade(String value) =>
          int.tryParse(RegExp(r'\d+').firstMatch(value)?.group(0) ?? '');
      final gradeOrder = (grade(a) ?? 999).compareTo(grade(b) ?? 999);
      return gradeOrder != 0 ? gradeOrder : a.compareTo(b);
    });
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = _options
        .where(
          (value) => value.toLowerCase().contains(_query.trim().toLowerCase()),
        )
        .toList();
    return AppModalSheetChrome(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SizedBox(
            height:
                (MediaQuery.sizeOf(context).height * 0.65 -
                        MediaQuery.viewInsetsOf(context).bottom)
                    .clamp(180.0, double.infinity),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Klassen auswählen',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Klasse suchen',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Alle Klassen'),
                  subtitle: Text(
                    _selected.isEmpty
                        ? 'Keine Einschränkung'
                        : '${_selected.length} ausgewählt',
                  ),
                  value: _selected.isEmpty,
                  onChanged: (_) {
                    AppHaptics.selection();
                    setState(_selected.clear);
                  },
                ),
                const Divider(height: 1),
                Expanded(
                  child: visible.isEmpty
                      ? Center(
                          child: Text(
                            _options.isEmpty
                                ? 'Keine Klassen verfügbar'
                                : 'Keine Klassen gefunden',
                          ),
                        )
                      : ListView.builder(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          itemCount: visible.length,
                          itemBuilder: (context, index) {
                            final value = visible[index];
                            return CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(value.toUpperCase()),
                              value: _selected.contains(value),
                              onChanged: (selected) {
                                AppHaptics.selection();
                                setState(() {
                                  if (selected == true) {
                                    _selected.add(value);
                                  } else {
                                    _selected.remove(value);
                                  }
                                });
                              },
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(_options.where(_selected.contains).toList()),
                    child: const Text('Auswahl übernehmen'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
