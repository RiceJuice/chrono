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
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        const SizedBox(height: 22),

        const Text('Stimme', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double w = constraints.maxWidth;
            final double menuWidth = w > 360 ? 360 : w;
            return DropdownMenu<String>(
              width: menuWidth,
              menuHeight: loginDropdownMenuMaxHeight(context),
              menuStyle: loginDropdownMenuSurfaceStyle(context),
              decorationBuilder: (BuildContext context, MenuController _) {
                assert(debugCheckHasMaterial(context));
                return loginDropdownDecorationWithOpenHaptic(
                  loginInputDecoration('Stimme'),
                );
              },
              initialSelection: hasSelection ? selectedVoice : null,
              onSelected: (String? voice) {
                if (voice != null) {
                  loginDropdownSelectionHaptic();
                  onVoiceChanged(voice);
                }
              },
              enableSearch: false,
              enableFilter: false,
              selectOnly: true,
              textStyle: TextStyle(color: scheme.onSurface),
              trailingIcon: Icon(Icons.arrow_drop_down, color: scheme.onSurface),
              dropdownMenuEntries: loginDropdownMenuEntries<String>(
                context,
                _voices,
                width: menuWidth,
                labelOf: (String v) => v,
              ),
            );
          },
        ),
      ],
    );
  }
}
