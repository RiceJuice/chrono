import 'package:flutter/widgets.dart';

/// TextController mit eingebauter Draft-Synchronisation via Listener.
class DraftTextController extends TextEditingController {
  DraftTextController({
    required String initialValue,
    required ValueChanged<String> onChanged,
  }) : _onChanged = onChanged,
       super(text: initialValue) {
    addListener(_syncToDraft);
  }

  final ValueChanged<String> _onChanged;

  void _syncToDraft() => _onChanged(text);

  @override
  void dispose() {
    removeListener(_syncToDraft);
    super.dispose();
  }
}
