import 'package:chronoapp/features/homework/data/homework_id_generator.dart';
import 'package:chronoapp/features/homework/domain/models/homework_task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('homeworkContributionId ist stabil fuer gleichen Schluessel', () {
    final date = DateTime(2026, 6, 27);
    final a = homeworkContributionId(
      profileId: 'user-1',
      className: '10a',
      schooltrack: 'G8',
      subjectId: 'latin',
      lessonDate: date,
    );
    final b = homeworkContributionId(
      profileId: 'user-1',
      className: '10a',
      schooltrack: 'G8',
      subjectId: 'latin',
      lessonDate: date,
    );

    expect(a, b);
    expect(a, isNot(equals(generateHomeworkId())));
  });
}
