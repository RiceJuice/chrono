enum SchoolAssessmentScheduleSource {
  lessonSlot,
  customDate,
}

SchoolAssessmentScheduleSource? schoolAssessmentScheduleSourceFromJson(
  String? value,
) {
  return switch (value) {
    'lesson_slot' => SchoolAssessmentScheduleSource.lessonSlot,
    'custom_date' => SchoolAssessmentScheduleSource.customDate,
    _ => null,
  };
}

String schoolAssessmentScheduleSourceToJson(
  SchoolAssessmentScheduleSource source,
) {
  return switch (source) {
    SchoolAssessmentScheduleSource.lessonSlot => 'lesson_slot',
    SchoolAssessmentScheduleSource.customDate => 'custom_date',
  };
}
