import 'dart:convert';

enum HomeworkFragmentKind {
  book,
  worksheet,
  notebook,
  online,
  format,
  freeText,
}

HomeworkFragmentKind homeworkFragmentKindFromJson(String? value) {
  return switch (value) {
    'book' => HomeworkFragmentKind.book,
    'worksheet' => HomeworkFragmentKind.worksheet,
    'notebook' => HomeworkFragmentKind.notebook,
    'online' => HomeworkFragmentKind.online,
    'format' => HomeworkFragmentKind.format,
    'free_text' => HomeworkFragmentKind.freeText,
    _ => HomeworkFragmentKind.freeText,
  };
}

String homeworkFragmentKindToJson(HomeworkFragmentKind kind) {
  return switch (kind) {
    HomeworkFragmentKind.book => 'book',
    HomeworkFragmentKind.worksheet => 'worksheet',
    HomeworkFragmentKind.notebook => 'notebook',
    HomeworkFragmentKind.online => 'online',
    HomeworkFragmentKind.format => 'format',
    HomeworkFragmentKind.freeText => 'free_text',
  };
}

class HomeworkFragment {
  const HomeworkFragment({
    required this.kind,
    required this.canonicalKey,
    required this.displayText,
    this.chipColorKey = 'default',
    this.fields = const {},
  });

  final HomeworkFragmentKind kind;
  final String canonicalKey;
  final String displayText;
  final String chipColorKey;
  final Map<String, dynamic> fields;

  HomeworkFragment copyWith({
    HomeworkFragmentKind? kind,
    String? canonicalKey,
    String? displayText,
    String? chipColorKey,
    Map<String, dynamic>? fields,
  }) {
    return HomeworkFragment(
      kind: kind ?? this.kind,
      canonicalKey: canonicalKey ?? this.canonicalKey,
      displayText: displayText ?? this.displayText,
      chipColorKey: chipColorKey ?? this.chipColorKey,
      fields: fields ?? this.fields,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kind': homeworkFragmentKindToJson(kind),
      'canonical_key': canonicalKey,
      'display_text': displayText,
      'chip_color_key': chipColorKey,
      'fields': fields,
    };
  }

  factory HomeworkFragment.fromJson(Map<String, dynamic> json) {
    return HomeworkFragment(
      kind: homeworkFragmentKindFromJson(json['kind'] as String?),
      canonicalKey: json['canonical_key'] as String? ?? '',
      displayText: json['display_text'] as String? ?? '',
      chipColorKey: json['chip_color_key'] as String? ?? 'default',
      fields: json['fields'] is Map
          ? Map<String, dynamic>.from(json['fields'] as Map)
          : const {},
    );
  }
}

List<HomeworkFragment> homeworkFragmentsFromJson(dynamic raw) {
  if (raw is String) {
    if (raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      return homeworkFragmentsFromJson(decoded);
    } catch (_) {
      return const [];
    }
  }
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => HomeworkFragment.fromJson(Map<String, dynamic>.from(e)))
      .toList(growable: false);
}

String encodeFragmentsJson(List<HomeworkFragment> fragments) {
  return jsonEncode(fragments.map((f) => f.toJson()).toList());
}

String fragmentsToPlainText(List<HomeworkFragment> fragments) {
  if (fragments.isEmpty) return '';
  return fragments.map((f) => f.displayText).join(' ');
}
