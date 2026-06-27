import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:chronoapp/features/homework/domain/models/homework_task.dart';

String generateHomeworkId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  return _formatUuid(bytes);
}

/// Stabile ID pro Nutzer/Fach/Tag — verhindert Duplicate-Key-Konflikte beim Upload.
String homeworkContributionId({
  required String profileId,
  required String className,
  String? schooltrack,
  required String subjectId,
  required DateTime lessonDate,
}) {
  final key = [
    profileId,
    className.trim(),
    (schooltrack ?? '').trim().toLowerCase(),
    subjectId,
    formatLessonDate(lessonDate),
  ].join('|');

  final digest = sha256.convert(utf8.encode(key)).bytes;
  final bytes = List<int>.from(digest.take(16));
  bytes[6] = (bytes[6] & 0x0f) | 0x50;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  return _formatUuid(bytes);
}

String _formatUuid(List<int> bytes) {
  String hex(int value) => value.toRadixString(16).padLeft(2, '0');
  final b = bytes;
  return '${hex(b[0])}${hex(b[1])}${hex(b[2])}${hex(b[3])}-'
      '${hex(b[4])}${hex(b[5])}-'
      '${hex(b[6])}${hex(b[7])}-'
      '${hex(b[8])}${hex(b[9])}-'
      '${hex(b[10])}${hex(b[11])}${hex(b[12])}${hex(b[13])}${hex(b[14])}${hex(b[15])}';
}
