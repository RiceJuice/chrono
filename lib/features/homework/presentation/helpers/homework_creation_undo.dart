import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> offerHomeworkCreationUndo({
  required ScaffoldMessengerState messenger,
  required ColorScheme colors,
  required Future<void> Function() deleteTask,
}) async {
  const message = 'Aufgabe erstellt';
  const action = 'Rückgängig';

  Future<void> undo() async {
    try {
      await deleteTask();
    } catch (_) {
      if (!messenger.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Aufgabe konnte nicht gelöscht werden.')),
      );
    }
  }

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    try {
      final tapped = await const MethodChannel(
        'chrono/homework_undo',
      ).invokeMethod<bool>('show', {'message': message, 'action': action});
      if (tapped == true) await undo();
      return;
    } on MissingPluginException {
      // A running build may not have the native handler yet.
    } on PlatformException {
      // Fall back when the native window is unavailable.
    }
  }

  if (!messenger.mounted) return;
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
      elevation: 1,
      backgroundColor: colors.surfaceContainerHighest,
      showCloseIcon: false,
      content: Text(message, style: TextStyle(color: colors.onSurface)),
      action: SnackBarAction(
        label: action,
        textColor: colors.onSurfaceVariant,
        onPressed: undo,
      ),
    ),
  );
}
