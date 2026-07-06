import 'package:flutter/material.dart';

enum SchoolAssessmentKind {
  schulaufgabe,
  referat,
  stegreifaufgabe,
}

extension SchoolAssessmentKindLabels on SchoolAssessmentKind {
  String get label => switch (this) {
        SchoolAssessmentKind.schulaufgabe => 'Schulaufgabe',
        SchoolAssessmentKind.referat => 'Referat',
        SchoolAssessmentKind.stegreifaufgabe => 'Stegreifaufgabe',
      };

  IconData get icon => switch (this) {
        SchoolAssessmentKind.schulaufgabe => Icons.quiz_outlined,
        SchoolAssessmentKind.referat => Icons.record_voice_over_outlined,
        SchoolAssessmentKind.stegreifaufgabe => Icons.bolt_outlined,
      };

  String get previewTooltipSuffix => switch (this) {
        SchoolAssessmentKind.schulaufgabe => 'Schulaufgabe in einer Woche',
        SchoolAssessmentKind.referat => 'Referat in einer Woche',
        SchoolAssessmentKind.stegreifaufgabe => 'Stegreifaufgabe in einer Woche',
      };
}

SchoolAssessmentKind? schoolAssessmentKindFromJson(String? value) {
  return switch (value) {
    'schulaufgabe' => SchoolAssessmentKind.schulaufgabe,
    'referat' => SchoolAssessmentKind.referat,
    'stegreifaufgabe' => SchoolAssessmentKind.stegreifaufgabe,
    _ => null,
  };
}

String schoolAssessmentKindToJson(SchoolAssessmentKind kind) {
  return switch (kind) {
    SchoolAssessmentKind.schulaufgabe => 'schulaufgabe',
    SchoolAssessmentKind.referat => 'referat',
    SchoolAssessmentKind.stegreifaufgabe => 'stegreifaufgabe',
  };
}
