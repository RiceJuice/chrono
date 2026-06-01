import 'package:flutter/material.dart';

/// Hex-Farben für [subjects.default_color] und Profil-Overrides.
class SubjectColorCodec {
  SubjectColorCodec._();

  static final RegExp _hexPattern = RegExp(r'^#([0-9A-Fa-f]{6})$');

  static Color? parseHex(Object? value) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) return null;
    final match = _hexPattern.firstMatch(raw);
    if (match == null) return null;
    final hex = match.group(1)!;
    final argb = int.parse(hex, radix: 16);
    return Color(0xFF000000 | argb);
  }

  static String toHex(Color color) {
    final rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
