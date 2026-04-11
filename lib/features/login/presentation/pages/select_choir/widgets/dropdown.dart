import 'package:flutter/material.dart';

import '../../../widgets/login_dropdown_menu.dart';
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
    final bool hasSelection = _voices.contains(selectedVoice);

    return Column(
      children: [
        const SizedBox(height: 22),

        const Text('Stimme', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double w = constraints.maxWidth;
            return DropdownMenu<String>(
              width: w,
              menuHeight: loginDropdownMenuMaxHeight(context),
              menuStyle: loginDropdownMenuSurfaceStyle(),
              decorationBuilder: (BuildContext context, MenuController _) {
                assert(debugCheckHasMaterial(context));
                return loginInputDecoration('Stimme');
              },
              initialSelection: hasSelection ? selectedVoice : null,
              onSelected: (String? voice) {
                if (voice != null) {
                  onVoiceChanged(voice);
                }
              },
              enableSearch: false,
              enableFilter: false,
              selectOnly: true,
              textStyle: const TextStyle(color: Colors.white),
              dropdownMenuEntries: loginDropdownMenuEntries<String>(
                _voices,
                width: w,
                labelOf: (String v) => v,
              ),
            );
          },
        ),
      ],
    );
  }
}
