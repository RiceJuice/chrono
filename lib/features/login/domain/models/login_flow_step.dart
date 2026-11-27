import 'package:flutter/material.dart';

enum LoginFlowStep {
  credentials,
  role,
  personalData,
  musicLessons,
  choir,
  selectChild,
  guardianPending,
}

extension LoginFlowStepX on LoginFlowStep {
  int get stepNumber => switch (this) {
    LoginFlowStep.credentials => 1,
    LoginFlowStep.role => 2,
    LoginFlowStep.personalData => 3,
    LoginFlowStep.musicLessons => 4,
    LoginFlowStep.choir => 5,
    LoginFlowStep.selectChild => 4,
    LoginFlowStep.guardianPending => 4,
  };

  Color get accentColor => switch (this) {
    LoginFlowStep.credentials => const Color(0xFFCBBBA0),
    LoginFlowStep.role => const Color(0xFF0B5A38),
    LoginFlowStep.personalData => const Color(0xFFB33B0B),
    LoginFlowStep.musicLessons => const Color(0xFF6645A1),
    LoginFlowStep.choir => const Color(0xFF0B4AA5),
    LoginFlowStep.selectChild => const Color(0xFF0B4AA5),
    LoginFlowStep.guardianPending => const Color(0xFF0B4AA5),
  };

  String get title => switch (this) {
    LoginFlowStep.credentials => 'Zugangsdaten',
    LoginFlowStep.role => 'Wer bist du?',
    LoginFlowStep.personalData => 'Deine Daten',
    LoginFlowStep.musicLessons => 'Dein Musikunterricht',
    LoginFlowStep.choir => 'Dein Chor',
    LoginFlowStep.selectChild => 'Kind auswählen',
    LoginFlowStep.guardianPending => 'Bestätigung',
  };
}
