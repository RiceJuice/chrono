import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Dezente Phosphor-Icons für den Login-Flow (Credentials, Social).
abstract final class LoginAuthIcons {
  LoginAuthIcons._();

  static const PhosphorIconsStyle _style = PhosphorIconsStyle.regular;

  static IconData get email => PhosphorIcons.envelopeSimple(_style);
  static IconData get password => PhosphorIcons.lock(_style);
  static IconData get passwordConfirm => PhosphorIcons.lockKey(_style);
  static IconData get visibility => PhosphorIcons.eye(_style);
  static IconData get visibilityOff => PhosphorIcons.eyeSlash(_style);
  static IconData get apple => Icons.apple;
}
