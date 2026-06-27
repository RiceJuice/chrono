import 'models/homework_fragment.dart';
import 'models/homework_syntax_suggestion.dart';

enum HomeworkParseContext {
  start,
  afterBook,
  afterPage,
  afterSlash,
  freeText,
}

class ParsedHomeworkLine {
  const ParsedHomeworkLine({
    required this.committedFragments,
    required this.activeText,
    required this.context,
  });

  final List<HomeworkFragment> committedFragments;
  final String activeText;
  final HomeworkParseContext context;
}

class HomeworkSyntaxParser {
  HomeworkSyntaxParser({required List<HomeworkSyntaxSuggestion> suggestions})
      : _suggestions = suggestions {
    _buildLookup();
  }

  final List<HomeworkSyntaxSuggestion> _suggestions;
  late final Map<String, HomeworkSyntaxSuggestion> _lookup;

  void _buildLookup() {
    _lookup = {};
    for (final suggestion in _suggestions) {
      for (final trigger in suggestion.allTriggers) {
        _lookup[_normalize(trigger)] = suggestion;
      }
    }
  }

  static String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(' ', '');

  ParsedHomeworkLine parse({
    required List<HomeworkFragment> committedFragments,
    required String activeText,
  }) {
    return ParsedHomeworkLine(
      committedFragments: committedFragments,
      activeText: activeText,
      context: _resolveContext(committedFragments),
    );
  }

  /// Wird bei Leerzeichen, `/` oder Enter aufgerufen — nicht bei jedem Tastendruck.
  ParsedHomeworkLine? commitActiveText({
    required List<HomeworkFragment> committedFragments,
    required String activeText,
  }) {
    final context = _resolveContext(committedFragments);
    final trimmed = activeText.trimLeft();
    final tokenBody = trimmed.trim();
    if (tokenBody.isEmpty) return null;

    if (context == HomeworkParseContext.afterBook) {
      final slashPage = RegExp(r'^(\d+)/$').firstMatch(tokenBody);
      if (slashPage != null) {
        return _applyBookPage(
          committedFragments: committedFragments,
          page: slashPage.group(1)!,
        );
      }

      final pageOnly = RegExp(r'^(\d+)$').firstMatch(tokenBody);
      if (pageOnly != null && activeText.endsWith(' ')) {
        return _applyBookPage(
          committedFragments: committedFragments,
          page: pageOnly.group(1)!,
        );
      }
    }

    if (context == HomeworkParseContext.afterPage) {
      final exerciseSlash = RegExp(r'^/?(\d+)$').firstMatch(tokenBody);
      if (exerciseSlash != null &&
          (activeText.endsWith(' ') || activeText.endsWith('/'))) {
        return _applyBookExercise(
          committedFragments: committedFragments,
          exercise: exerciseSlash.group(1)!,
        );
      }
    }

    if (!activeText.endsWith(' ')) {
      return null;
    }

    final token = tokenBody;
    if (token.isEmpty) {
      return ParsedHomeworkLine(
        committedFragments: committedFragments,
        activeText: '',
        context: context,
      );
    }

    final bookMatch = _matchBookReference(token, committedFragments);
    if (bookMatch != null) return bookMatch;

    final suggestionMatch = _matchSuggestionToken(
      committedFragments: committedFragments,
      token: token,
    );
    if (suggestionMatch != null) return suggestionMatch;

    return ParsedHomeworkLine(
      committedFragments: [...committedFragments, _freeTextFragment(token)],
      activeText: '',
      context: HomeworkParseContext.start,
    );
  }

  List<HomeworkFragment> parseCompleteLine(String input) {
    var committed = <HomeworkFragment>[];
    var active = input.trim();

    for (var i = 0; i < 30; i++) {
      if (active.isEmpty) break;

      final bookInline = _matchBookReference(active, committed);
      if (bookInline != null) {
        committed = bookInline.committedFragments;
        active = bookInline.activeText.trim();
        continue;
      }

      final spaceIdx = active.indexOf(' ');
      if (spaceIdx == -1) {
        break;
      }

      final chunk = active.substring(0, spaceIdx + 1);
      final committedLine = commitActiveText(
        committedFragments: committed,
        activeText: chunk,
      );
      if (committedLine != null) {
        committed = committedLine.committedFragments;
        active = active.substring(spaceIdx + 1).trim();
        continue;
      }

      committed = [...committed, _freeTextFragment(chunk.trim())];
      active = active.substring(spaceIdx + 1).trim();
    }

    if (active.isNotEmpty) {
      final bookInline = _matchBookReference(active, committed);
      if (bookInline != null) {
        committed = bookInline.committedFragments;
      } else {
        final suggestion = _lookup[_normalize(active)];
        if (suggestion != null) {
          committed = [...committed, _fragmentFromSuggestion(suggestion)];
        } else {
          committed = [...committed, _freeTextFragment(active)];
        }
      }
    }

    return committed;
  }

  HomeworkParseContext _resolveContext(List<HomeworkFragment> fragments) {
    if (fragments.isEmpty) return HomeworkParseContext.start;
    final last = fragments.last;
    return switch (last.kind) {
      HomeworkFragmentKind.book => last.fields['page'] == null
          ? HomeworkParseContext.afterBook
          : last.fields['exercise'] == null
              ? HomeworkParseContext.afterPage
              : HomeworkParseContext.start,
      _ => HomeworkParseContext.start,
    };
  }

  ParsedHomeworkLine _applyBookPage({
    required List<HomeworkFragment> committedFragments,
    required String page,
  }) {
    if (committedFragments.isEmpty) {
      return parse(
        committedFragments: committedFragments,
        activeText: page,
      );
    }
    final last = committedFragments.last;
    if (last.kind != HomeworkFragmentKind.book) {
      return parse(committedFragments: committedFragments, activeText: page);
    }

    final code = last.fields['code'] as String? ?? last.displayText;
    final updated = last.copyWith(
      displayText: '$code $page',
      canonicalKey: _bookCanonicalKey(code, page, null),
      fields: {...last.fields, 'page': page},
    );
    final next = [...committedFragments.sublist(0, committedFragments.length - 1), updated];
    return ParsedHomeworkLine(
      committedFragments: next,
      activeText: '',
      context: HomeworkParseContext.afterPage,
    );
  }

  ParsedHomeworkLine _applyBookExercise({
    required List<HomeworkFragment> committedFragments,
    required String exercise,
  }) {
    final last = committedFragments.last;
    final code = last.fields['code'] as String;
    final page = last.fields['page'] as String;
    final updated = last.copyWith(
      displayText: _bookDisplayText(code: code, page: page, exercise: exercise),
      canonicalKey: _bookCanonicalKey(code, page, exercise),
      fields: {...last.fields, 'exercise': exercise},
    );
    final next = [...committedFragments.sublist(0, committedFragments.length - 1), updated];
    return ParsedHomeworkLine(
      committedFragments: next,
      activeText: '',
      context: HomeworkParseContext.start,
    );
  }

  ParsedHomeworkLine? _matchBookReference(
    String text,
    List<HomeworkFragment> committedFragments,
  ) {
    final match = RegExp(
      r'^([A-Za-zÄÖÜäöüß.]{1,8})\s*([Ss]\.?)?\s*(\d+)\s*(?:/(\d+)|(?:Aufg\.?|A\.?|Nr\.?|Ü\.?)\s*(\d+))?$',
    ).firstMatch(text.trim());
    if (match == null) return null;

    final codeRaw = match.group(1) ?? '';
    final suggestion = _lookup[_normalize(codeRaw)];
    if (suggestion == null || suggestion.category != 'book') return null;

    final page = match.group(3)!;
    final exercise = match.group(4) ?? match.group(5);
    final fragment = HomeworkFragment(
      kind: HomeworkFragmentKind.book,
      canonicalKey: _bookCanonicalKey(suggestion.shorthand, page, exercise),
      displayText: _bookDisplayText(
        code: suggestion.shorthand,
        page: page,
        exercise: exercise,
      ),
      chipColorKey: suggestion.chipColorKey,
      fields: {
        'code': suggestion.shorthand,
        'page': page,
        if (exercise != null) 'exercise': exercise,
      },
    );

    return ParsedHomeworkLine(
      committedFragments: [...committedFragments, fragment],
      activeText: '',
      context: exercise == null
          ? HomeworkParseContext.afterPage
          : HomeworkParseContext.start,
    );
  }

  ParsedHomeworkLine? _matchSuggestionToken({
    required List<HomeworkFragment> committedFragments,
    required String token,
  }) {
    final suggestion = _lookup[_normalize(token)];
    if (suggestion == null) return null;

    return ParsedHomeworkLine(
      committedFragments: [...committedFragments, _fragmentFromSuggestion(suggestion)],
      activeText: '',
      context: suggestion.category == 'book'
          ? HomeworkParseContext.afterBook
          : HomeworkParseContext.start,
    );
  }

  HomeworkFragment _fragmentFromSuggestion(HomeworkSyntaxSuggestion suggestion) {
    final kind = switch (suggestion.category) {
      'book' => HomeworkFragmentKind.book,
      'worksheet' => HomeworkFragmentKind.worksheet,
      'notebook' => HomeworkFragmentKind.notebook,
      'online' => HomeworkFragmentKind.online,
      _ => HomeworkFragmentKind.format,
    };

    return HomeworkFragment(
      kind: kind,
      canonicalKey: '${suggestion.category}:${_normalize(suggestion.shorthand)}',
      displayText: suggestion.shorthand,
      chipColorKey: suggestion.chipColorKey,
      fields: {'code': suggestion.shorthand},
    );
  }

  HomeworkFragment _freeTextFragment(String text) {
    return HomeworkFragment(
      kind: HomeworkFragmentKind.freeText,
      canonicalKey: 'text:${_normalize(text)}',
      displayText: text,
      chipColorKey: 'default',
      fields: {'text': text},
    );
  }

  String _bookCanonicalKey(String code, String page, String? exercise) {
    final base = 'book:${_normalize(code)}:$page';
    return exercise == null ? base : '$base:$exercise';
  }

  String _bookDisplayText({
    required String code,
    required String page,
    String? exercise,
  }) {
    if (exercise == null) return '$code $page';
    return '$code $page/$exercise';
  }

  List<HomeworkSyntaxSuggestion> suggestionsForContext({
    required HomeworkParseContext context,
    required String activeText,
  }) {
    final query = activeText.trim().toLowerCase();

    if (context == HomeworkParseContext.afterBook) {
      if (query.isEmpty || RegExp(r'^\d*$').hasMatch(query)) {
        return const [];
      }
    }

    if (context == HomeworkParseContext.afterPage) {
      if (query.isEmpty || RegExp(r'^/?\d*$').hasMatch(query)) {
        return const [];
      }
    }

    Iterable<HomeworkSyntaxSuggestion> pool = _suggestions;

    if (query.isEmpty) {
      return pool.take(20).toList(growable: false);
    }

    return pool
        .where((s) {
          final triggers = s.allTriggers.map((t) => t.toLowerCase());
          return triggers.any((t) => t.startsWith(query)) ||
              s.label.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }
}
