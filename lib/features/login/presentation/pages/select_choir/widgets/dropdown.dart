import 'package:flutter/material.dart';
import '../../../widgets/login_input_decoration.dart';

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
    final String? value =
        _voices.contains(selectedVoice) ? selectedVoice : null;

    return Column(
      children: [
        const SizedBox(height: 22),

        const Text('Stimme', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: const Color(0xFF121212),
          iconEnabledColor: Colors.white,
          style: const TextStyle(color: Colors.white),
          decoration: loginInputDecoration('Stimme'),
          items: _voices
              .map(
                (voice) =>
                    DropdownMenuItem<String>(value: voice, child: Text(voice)),
              )
              .toList(),
          onChanged: (voice) {
            if (voice != null) {
              onVoiceChanged(voice);
            }
          },
        ),
      ],
    );
  }
}
