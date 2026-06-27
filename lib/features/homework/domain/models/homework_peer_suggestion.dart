import 'homework_fragment.dart';
import 'homework_task.dart';

class HomeworkPeerSuggestion {
  const HomeworkPeerSuggestion({
    required this.fragment,
    required this.subjectId,
    required this.contributionId,
    required this.lessonDate,
    required this.dismissalKey,
  });

  final HomeworkFragment fragment;
  final String subjectId;
  final String contributionId;
  final DateTime lessonDate;
  final String dismissalKey;
}

String homeworkPeerDismissalKey({
  required String canonicalKey,
  required String subjectId,
  required DateTime lessonDate,
}) {
  return '$canonicalKey|$subjectId|${formatLessonDate(lessonDate)}';
}
