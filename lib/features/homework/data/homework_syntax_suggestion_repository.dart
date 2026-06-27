import 'dart:convert';

import 'package:chronoapp/core/database/powersync_schema.dart';
import 'package:chronoapp/features/homework/domain/models/homework_syntax_suggestion.dart';
import 'package:powersync/powersync.dart';
import 'package:sqlite3/common.dart';
import 'package:chronoapp/features/homework/data/homework_id_generator.dart';

class HomeworkSyntaxSuggestionRepository {
  HomeworkSyntaxSuggestionRepository(this._db);

  final PowerSyncDatabase _db;

  Stream<List<HomeworkSyntaxSuggestion>> watchSuggestions() {
    return _db
        .watch(
          '''
          SELECT *
          FROM $kHomeworkSyntaxSuggestionsTable
          ORDER BY sort_order ASC, label COLLATE NOCASE ASC
          ''',
          triggerOnTables: const {kHomeworkSyntaxSuggestionsTable},
        )
        .map(_mapSuggestions);
  }

  Future<String> createUserSuggestion({
    required String profileId,
    required String label,
    required String shorthand,
    String category = 'format',
    String chipColorKey = 'default',
  }) async {
    final id = generateHomeworkId();
    final now = DateTime.now().toUtc().toIso8601String();

    await _db.writeTransaction((tx) async {
      await tx.execute(
        '''
        INSERT INTO $kHomeworkSyntaxSuggestionsTable
          (id, category, label, shorthand, aliases, insert_template,
           chip_color_key, sort_order, is_global, created_by, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          id,
          category,
          label.trim(),
          shorthand.trim(),
          '[]',
          '{shorthand} ',
          chipColorKey,
          900,
          0,
          profileId,
          now,
        ],
      );
    });

    return id;
  }

  List<HomeworkSyntaxSuggestion> _mapSuggestions(ResultSet rows) {
    return rows
        .map((row) => HomeworkSyntaxSuggestion.fromRow(row))
        .toList(growable: false);
  }
}

String encodeAliasesJson(List<String> aliases) => jsonEncode(aliases);
