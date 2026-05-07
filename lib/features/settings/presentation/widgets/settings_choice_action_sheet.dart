import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsChoiceActionSheet extends StatefulWidget {
  const SettingsChoiceActionSheet({
    super.key,
    required this.title,
    required this.options,
    required this.initialValue,
  });

  final String title;
  final List<String> options;
  final String? initialValue;

  @override
  State<SettingsChoiceActionSheet> createState() =>
      _SettingsChoiceActionSheetState();
}

class _SettingsChoiceActionSheetState extends State<SettingsChoiceActionSheet> {
  final _selectedItemKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _selectedItemKey.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        duration: Duration.zero,
        alignment: 0.5,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 12),
            child: Text(
              widget.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          ...widget.options.map((option) {
            final isSelected = option == widget.initialValue;
            return ListTile(
              key: isSelected ? _selectedItemKey : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(option),
              trailing: isSelected
                  ? Icon(Icons.check_rounded, color: scheme.primary)
                  : null,
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop(option);
              },
            );
          }),
        ],
      ),
    );
  }
}
