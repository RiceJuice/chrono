import 'homework_fragment.dart';

class HomeworkContribution {
  const HomeworkContribution({
    required this.id,
    required this.profileId,
    required this.className,
    this.schooltrack,
    required this.subjectId,
    required this.lessonDate,
    required this.fragments,
    required this.fragmentHashes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String profileId;
  final String className;
  final String? schooltrack;
  final String subjectId;
  final DateTime lessonDate;
  final List<HomeworkFragment> fragments;
  final List<String> fragmentHashes;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory HomeworkContribution.fromRow(Map<String, dynamic> row) {
    return HomeworkContribution(
      id: row['id'] as String,
      profileId: row['profile_id'] as String,
      className: row['class_name'] as String? ?? '',
      schooltrack: row['schooltrack'] as String?,
      subjectId: row['subject_id'] as String,
      lessonDate: DateTime.parse(row['lesson_date'] as String),
      fragments: homeworkFragmentsFromJson(row['fragments']),
      fragmentHashes: _parseHashes(row['fragment_hashes']),
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(row['updated_at'] as String).toLocal(),
    );
  }

  static List<String> _parseHashes(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList(growable: false);
    }
    final text = raw.toString().trim();
    if (text.startsWith('[')) {
      return text
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '')
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }
    return [text];
  }
}
