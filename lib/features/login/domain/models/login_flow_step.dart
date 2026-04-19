import 'package:flutter/material.dart';

enum LoginFlowStep { credentials, role, personalData, choir }

extension LoginFlowStepX on LoginFlowStep {
  int get stepNumber => switch (this) {
    LoginFlowStep.credentials => 1,
    LoginFlowStep.role => 2,
    LoginFlowStep.personalData => 3,
    LoginFlowStep.choir => 4,
  };

  Color get accentColor => switch (this) {
    LoginFlowStep.credentials => const Color(0xFFCBBBA0),
    LoginFlowStep.role => const Color(0xFF0B5A38),
    LoginFlowStep.personalData => const Color(0xFFB33B0B),
    LoginFlowStep.choir => const Color(0xFF0B4AA5),
  };

  /// Standard-Schrittüberschrift (rollenabhängige Varianten setzt das Login-UI).
  String get title => switch (this) {
    LoginFlowStep.credentials => 'Zugangsdaten',
    LoginFlowStep.role => 'Wer bist du?',
    LoginFlowStep.personalData => 'Deine Daten',
    LoginFlowStep.choir => 'Dein Chor',
  };
}
