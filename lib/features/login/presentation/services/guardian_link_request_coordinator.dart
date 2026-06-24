import 'package:flutter/foundation.dart';

/// Koordiniert Hintergrund-Versand von Verknüpfungsanfragen nach Navigation
/// zum Bestätigungs-Screen.
final class GuardianLinkRequestCoordinator extends ChangeNotifier {
  GuardianLinkRequestCoordinator._();

  static final GuardianLinkRequestCoordinator instance =
      GuardianLinkRequestCoordinator._();

  bool _sending = false;
  String? _errorMessage;

  bool get isSending => _sending;
  String? get errorMessage => _errorMessage;

  void markSending() {
    _sending = true;
    _errorMessage = null;
    notifyListeners();
  }

  void markDone() {
    _sending = false;
    _errorMessage = null;
    notifyListeners();
  }

  void markFailed(String message) {
    _sending = false;
    _errorMessage = message;
    notifyListeners();
  }

  void reset() {
    _sending = false;
    _errorMessage = null;
    notifyListeners();
  }
}
