import 'package:flutter/material.dart';

enum LoginFlowStep { register, role, personalData, choir }

extension LoginFlowStepX on LoginFlowStep {
  int get stepNumber => switch (this) {
    LoginFlowStep.register => 1,
    LoginFlowStep.role => 2,
    LoginFlowStep.personalData => 3,
    LoginFlowStep.choir => 4,
  };

  Color get accentColor => switch (this) {
    LoginFlowStep.register => const Color(0xFFCBBBA0),
    LoginFlowStep.role => const Color(0xFF0B5A38),
    LoginFlowStep.personalData => const Color(0xFFB33B0B),
    LoginFlowStep.choir => const Color(0xFF0B4AA5),
  };

  String get title => switch (this) {
    LoginFlowStep.register => 'Registrieren',
    LoginFlowStep.role => 'Wer bist du?',
    LoginFlowStep.personalData => 'Deine Daten',
    LoginFlowStep.choir => 'Dein Chor',
  };
}
