/// Status einer Eltern-Kind-Verknüpfung (Werte wie in Postgres CHECK).
abstract final class GuardianLinkStatus {
  static const pending = 'pending';
  static const confirmed = 'confirmed';
  static const rejected = 'rejected';
  static const revoked = 'revoked';
}

class StudentSearchResult {
  const StudentSearchResult({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.className,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? className;

  String get displayName {
    final parts = [firstName, lastName]
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty);
    return parts.join(' ');
  }

  String get displaySubtitle {
    final name = displayName;
    final cls = className?.trim();
    if (cls == null || cls.isEmpty) return name;
    return '$name · Klasse $cls';
  }

  factory StudentSearchResult.fromJson(Map<String, dynamic> json) {
    var firstName = json['first_name']?.toString().trim() ?? '';
    var lastName = json['last_name']?.toString().trim() ?? '';
    final profileName = json['profile_name']?.toString().trim() ?? '';

    if (firstName.isEmpty && lastName.isEmpty && profileName.isNotEmpty) {
      final parts = profileName.split(RegExp(r'\s+'));
      if (parts.isNotEmpty) firstName = parts.first;
      if (parts.length > 1) lastName = parts.sublist(1).join(' ');
    }

    return StudentSearchResult(
      id: json['student_id']?.toString() ?? json['id']?.toString() ?? '',
      firstName: firstName,
      lastName: lastName,
      className: json['class_name']?.toString(),
    );
  }
}

class GuardianChildLink {
  const GuardianChildLink({
    required this.id,
    required this.guardianId,
    required this.childId,
    required this.status,
    this.createdAt,
    this.respondedAt,
    this.reminderSentAt,
    this.childFirstName,
    this.childLastName,
    this.childClassName,
    this.guardianFirstName,
    this.guardianLastName,
  });

  final String id;
  final String guardianId;
  final String childId;
  final String status;
  final DateTime? createdAt;
  final DateTime? respondedAt;
  final DateTime? reminderSentAt;
  final String? childFirstName;
  final String? childLastName;
  final String? childClassName;
  final String? guardianFirstName;
  final String? guardianLastName;

  bool get isPending => status == GuardianLinkStatus.pending;
  bool get isConfirmed => status == GuardianLinkStatus.confirmed;

  String get childDisplayName {
    final parts = [childFirstName, childLastName]
        .map((p) => p?.trim())
        .whereType<String>()
        .where((p) => p.isNotEmpty);
    return parts.isEmpty ? 'Kind' : parts.join(' ');
  }

  String get guardianDisplayName {
    final parts = [guardianFirstName, guardianLastName]
        .map((p) => p?.trim())
        .whereType<String>()
        .where((p) => p.isNotEmpty);
    return parts.isEmpty ? 'Elternteil' : parts.join(' ');
  }

  factory GuardianChildLink.fromRow(Map<String, dynamic> row) {
    return GuardianChildLink(
      id: row['id']?.toString() ?? '',
      guardianId: row['guardian_id']?.toString() ?? '',
      childId: row['child_id']?.toString() ?? '',
      status: row['status']?.toString() ?? GuardianLinkStatus.pending,
      createdAt: _parseDateTime(row['created_at']),
      respondedAt: _parseDateTime(row['responded_at']),
      reminderSentAt: _parseDateTime(row['reminder_sent_at']),
      childFirstName: row['child_first_name']?.toString(),
      childLastName: row['child_last_name']?.toString(),
      childClassName: row['child_class_name']?.toString(),
      guardianFirstName: row['guardian_first_name']?.toString(),
      guardianLastName: row['guardian_last_name']?.toString(),
    );
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
