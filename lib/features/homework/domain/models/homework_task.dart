import 'homework_fragment.dart';

enum HomeworkDueSource {
  nextLesson,
  customDate,
}

HomeworkDueSource? homeworkDueSourceFromJson(String? value) {
  return switch (value) {
    'next_lesson' => HomeworkDueSource.nextLesson,
    'custom_date' => HomeworkDueSource.customDate,
    _ => null,
  };
}

String homeworkDueSourceToJson(HomeworkDueSource source) {
  return switch (source) {
    HomeworkDueSource.nextLesson => 'next_lesson',
    HomeworkDueSource.customDate => 'custom_date',
  };
}

class HomeworkTask {
  const HomeworkTask({
    required this.id,
    required this.title,
    this.description,
    this.fragments = const [],
    this.plainText,
    this.subjectId,
    required this.isCompleted,
    required this.createdAt,
    this.completedAt,
    this.dueAt,
    this.dueSource,
    this.contributionId,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final List<HomeworkFragment> fragments;
  final String? plainText;
  final String? subjectId;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? dueAt;
  final HomeworkDueSource? dueSource;
  final String? contributionId;
  final DateTime? updatedAt;

  String get displayDescription => description ?? plainText ?? '';

  HomeworkTask copyWith({
    String? id,
    String? title,
    String? description,
    List<HomeworkFragment>? fragments,
    String? plainText,
    String? subjectId,
    bool clearSubjectId = false,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? dueAt,
    HomeworkDueSource? dueSource,
    bool clearDueAt = false,
    bool clearDueSource = false,
    String? contributionId,
    DateTime? updatedAt,
  }) {
    return HomeworkTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      fragments: fragments ?? this.fragments,
      plainText: plainText ?? this.plainText,
      subjectId: clearSubjectId ? null : (subjectId ?? this.subjectId),
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: clearCompletedAt
          ? null
          : (completedAt ?? this.completedAt),
      dueAt: clearDueAt ? null : (dueAt ?? this.dueAt),
      dueSource: clearDueSource ? null : (dueSource ?? this.dueSource),
      contributionId: contributionId ?? this.contributionId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'fragments': fragments.map((f) => f.toJson()).toList(),
      'plain_text': plainText ?? displayDescription,
      'subject_id': subjectId,
      'is_completed': isCompleted,
      'created_at': createdAt.toUtc().toIso8601String(),
      'completed_at': completedAt?.toUtc().toIso8601String(),
      'due_at': dueAt?.toUtc().toIso8601String(),
      'due_source': dueSource == null ? null : homeworkDueSourceToJson(dueSource!),
      'contribution_id': contributionId,
      'updated_at': updatedAt?.toUtc().toIso8601String(),
    };
  }

  factory HomeworkTask.fromJson(Map<String, dynamic> json) {
    final fragments = homeworkFragmentsFromJson(json['fragments']);
    return HomeworkTask(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      fragments: fragments,
      plainText: json['plain_text'] as String?,
      subjectId: json['subject_id'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String).toLocal(),
      dueAt: json['due_at'] == null
          ? null
          : DateTime.parse(json['due_at'] as String).toLocal(),
      dueSource: homeworkDueSourceFromJson(json['due_source'] as String?),
      contributionId: json['contribution_id'] as String?,
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }

  factory HomeworkTask.fromRow(Map<String, dynamic> row) {
    final fragments = homeworkFragmentsFromJson(row['fragments']);
    return HomeworkTask(
      id: row['id'] as String,
      title: row['title'] as String,
      fragments: fragments,
      plainText: row['plain_text'] as String?,
      subjectId: row['subject_id'] as String?,
      isCompleted: row['is_completed'] == true || row['is_completed'] == 1,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      completedAt: row['completed_at'] == null
          ? null
          : DateTime.parse(row['completed_at'] as String).toLocal(),
      dueAt: row['due_at'] == null
          ? null
          : DateTime.parse(row['due_at'] as String).toLocal(),
      dueSource: homeworkDueSourceFromJson(row['due_source'] as String?),
      contributionId: row['contribution_id'] as String?,
      updatedAt: row['updated_at'] == null
          ? null
          : DateTime.parse(row['updated_at'] as String).toLocal(),
    );
  }
}

List<HomeworkTask> sortHomeworkTasks(Iterable<HomeworkTask> tasks) {
  final sorted = tasks.toList(growable: false);
  sorted.sort((a, b) {
    if (a.isCompleted != b.isCompleted) {
      return a.isCompleted ? 1 : -1;
    }
    if (!a.isCompleted && !b.isCompleted) {
      final dueCompare = _compareDueAt(a.dueAt, b.dueAt);
      if (dueCompare != 0) return dueCompare;
    }
    return b.createdAt.compareTo(a.createdAt);
  });
  return sorted;
}

int _compareDueAt(DateTime? a, DateTime? b) {
  if (a != null && b != null) return a.compareTo(b);
  if (a != null) return -1;
  if (b != null) return 1;
  return 0;
}

DateTime homeworkDueAtEndOfLocalDay(DateTime day) {
  final normalized = DateTime(day.year, day.month, day.day);
  return DateTime(
    normalized.year,
    normalized.month,
    normalized.day,
    23,
    59,
    59,
  );
}

String formatLessonDate(DateTime day) {
  return '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}
