import 'package:chronoapp/core/database/backend_enums.dart';

/// Gemeinsame Chor-Labels und Karussell-Assets für Login und Einstellungen.
abstract final class LoginChoirOptions {
  static const labels = <String>[
    'DKM',
    'Giehl',
    'Rädlinger',
    'Schola',
    'Szuczies',
  ];

  static const imageAssets = <String>[
    'assets/Carusell/Heiß.jpg',
    'assets/Carusell/Giehl.jpg',
    'assets/Carusell/Rädlinger.jpg',
    'assets/Carusell/Juric.png',
    'assets/Carusell/Szuczies.jpg',
  ];

  static String labelForPageIndex(int page) {
    return labels[page % labels.length];
  }

  static int pageIndexForLabel(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 0;
    final trimmed = raw.trim();
    final directIndex = labels.indexOf(trimmed);
    if (directIndex >= 0) return directIndex;
    final choir = BackendChoirCodec.fromBackend(trimmed);
    if (choir == BackendChoir.unknown) return 0;
    final displayIndex = labels.indexOf(choir.displayLabel);
    return displayIndex >= 0 ? displayIndex : 0;
  }
}
