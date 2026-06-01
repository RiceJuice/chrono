import 'package:flutter/material.dart';

/// Referenz-Fach aus [subjects] (Name + Standard-Akzentfarbe).
class CalendarSubject {
  const CalendarSubject({
    required this.id,
    required this.name,
    required this.defaultColor,
  });

  final String id;
  final String name;
  final Color defaultColor;
}
