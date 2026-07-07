import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Semantische Phosphor-Icons für die Einstellungen (iOS-Settings-Stil).
abstract final class SettingsIcons {
  SettingsIcons._();

  static const PhosphorIconsStyle _style = PhosphorIconsStyle.regular;

  static IconData get name => PhosphorIcons.userCircle(_style);
  static IconData get role => PhosphorIcons.identificationBadge(_style);
  static IconData get schoolClass => PhosphorIcons.student(_style);
  static IconData get schoolTrack => PhosphorIcons.signpost(_style);
  static IconData get calendar => PhosphorIcons.calendarBlank(_style);
  static IconData get choir => PhosphorIcons.musicNotes(_style);
  static IconData get voice => PhosphorIcons.microphoneStage(_style);
  static IconData get diet => PhosphorIcons.forkKnife(_style);
  static IconData get appearance => PhosphorIcons.palette(_style);
  static IconData get notifications => PhosphorIcons.bell(_style);
  static IconData get family => PhosphorIcons.usersThree(_style);
  static IconData get addChild => PhosphorIcons.userPlus(_style);
  static IconData get password => PhosphorIcons.lockKey(_style);
  static IconData get deleteAccount => PhosphorIcons.warningOctagon(_style);
  static IconData get chevron => PhosphorIcons.caretRight(_style);
  static IconData get logout => PhosphorIcons.signOut(_style);
  static IconData get error => PhosphorIcons.warningCircle(_style);
}
