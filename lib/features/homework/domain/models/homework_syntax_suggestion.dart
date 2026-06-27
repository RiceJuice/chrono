class HomeworkSyntaxSuggestion {
  const HomeworkSyntaxSuggestion({
    required this.id,
    required this.category,
    required this.label,
    required this.shorthand,
    this.aliases = const [],
    this.insertTemplate,
    this.chipColorKey = 'default',
    this.sortOrder = 0,
    this.isGlobal = true,
    this.createdBy,
  });

  final String id;
  final String category;
  final String label;
  final String shorthand;
  final List<String> aliases;
  final String? insertTemplate;
  final String chipColorKey;
  final int sortOrder;
  final bool isGlobal;
  final String? createdBy;

  Iterable<String> get allTriggers sync* {
    yield shorthand;
    if (label.trim().isNotEmpty) {
      yield label;
    }
    for (final alias in aliases) {
      if (alias.trim().isNotEmpty) yield alias;
    }
  }

  String resolveInsertText() {
    final template = insertTemplate ?? '{shorthand}';
    return template.replaceAll('{shorthand}', shorthand);
  }

  factory HomeworkSyntaxSuggestion.fromRow(Map<String, dynamic> row) {
    return HomeworkSyntaxSuggestion(
      id: row['id'] as String,
      category: row['category'] as String? ?? 'format',
      label: row['label'] as String? ?? '',
      shorthand: row['shorthand'] as String? ?? '',
      aliases: _parseAliases(row['aliases']),
      insertTemplate: row['insert_template'] as String?,
      chipColorKey: row['chip_color_key'] as String? ?? 'default',
      sortOrder: row['sort_order'] as int? ?? 0,
      isGlobal: row['is_global'] == true || row['is_global'] == 1,
      createdBy: row['created_by'] as String?,
    );
  }

  static List<String> _parseAliases(dynamic raw) {
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
