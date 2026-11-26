import 'package:flutter/material.dart';

import '../../../widgets/login_dropdown_field.dart';
import '../../../widgets/login_labeled_field.dart';

class Dropdown extends StatelessWidget {
  const Dropdown({
    super.key,
    required this.selectedVoice,
    required this.onVoiceChanged,
  });

  final String selectedVoice;
  final ValueChanged<String> onVoiceChanged;

  static const List<String> _voices = ['Tenor', 'Sopran', 'Alt', 'Bass'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 22),
        LoginLabeledField(
          label: 'Stimme',
          child: LoginDropdownField(
            selectedValue: _voices.contains(selectedVoice)
                ? selectedVoice
                : null,
            options: _voices,
            hintText: 'Stimme auswählen',
            label: 'Stimme',
            onChanged: (voice) {
              if (voice != null) onVoiceChanged(voice);
            },
          ),
        ),
      ],
    );
  }
}
