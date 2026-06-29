import 'package:chronoapp/features/homework/domain/homework_syntax_parser.dart';
import 'package:chronoapp/features/homework/domain/models/homework_fragment.dart';
import 'package:chronoapp/features/homework/domain/models/homework_syntax_suggestion.dart';
import 'package:flutter_test/flutter_test.dart';

List<HomeworkSyntaxSuggestion> _seedSuggestions() {
  return const [
    HomeworkSyntaxSuggestion(
      id: '1',
      category: 'book',
      label: 'Buchseite',
      shorthand: 'BS',
      aliases: ['Buchseite', 'B.S.', 'bs'],
      insertTemplate: '{shorthand} ',
      chipColorKey: 'book',
      sortOrder: 10,
    ),
    HomeworkSyntaxSuggestion(
      id: '2',
      category: 'worksheet',
      label: 'Arbeitsblatt',
      shorthand: 'AB',
      aliases: ['Arb.Bl.'],
      insertTemplate: '{shorthand} ',
      chipColorKey: 'worksheet',
      sortOrder: 100,
    ),
    HomeworkSyntaxSuggestion(
      id: '3',
      category: 'notebook',
      label: 'Hefteintrag',
      shorthand: 'HE',
      aliases: ['H.E.'],
      chipColorKey: 'notebook',
      sortOrder: 200,
    ),
    HomeworkSyntaxSuggestion(
      id: '4',
      category: 'notebook',
      label: 'Arbeitsheft',
      shorthand: 'AH',
      aliases: ['Arbeitsheft', 'A.H.', 'ah'],
      chipColorKey: 'notebook',
      sortOrder: 205,
    ),
  ];
}

void main() {
  late HomeworkSyntaxParser parser;

  setUp(() {
    parser = HomeworkSyntaxParser(suggestions: _seedSuggestions());
  });

  test('parst BS 117/3 kompakt', () {
    final fragments = parser.parseCompleteLine('BS 117/3');
    expect(fragments, hasLength(1));
    expect(fragments.first.kind, HomeworkFragmentKind.book);
    expect(fragments.first.fields['code'], 'BS');
    expect(fragments.first.fields['page'], '117');
    expect(fragments.first.fields['exercise'], '3');
    expect(fragments.first.displayText, 'BS 117/3');
  });

  test('parst BS117/3 ohne Leerzeichen', () {
    final fragments = parser.parseCompleteLine('BS117/3');
    expect(fragments.first.fields['page'], '117');
    expect(fragments.first.fields['exercise'], '3');
  });

  test('parst B.S. S.117 Aufg.3 tolerant', () {
    final fragments = parser.parseCompleteLine('B.S. S.117 Aufg.3');
    expect(fragments.first.fields['code'], 'BS');
    expect(fragments.first.fields['page'], '117');
    expect(fragments.first.fields['exercise'], '3');
  });

  test('parst Arbeitsblatt AB', () {
    final fragments = parser.parseCompleteLine('AB');
    expect(fragments, hasLength(1));
    expect(fragments[0].kind, HomeworkFragmentKind.worksheet);
  });

  test('parst Arbeitsheft AH', () {
    final fragments = parser.parseCompleteLine('AH');
    expect(fragments, hasLength(1));
    expect(fragments.first.kind, HomeworkFragmentKind.notebook);
    expect(fragments.first.fields['code'], 'AH');
  });

  test('parst Buchseite als Alias für BS', () {
    final fragments = parser.parseCompleteLine('Buchseite');
    expect(fragments, hasLength(1));
    expect(fragments.first.kind, HomeworkFragmentKind.book);
    expect(fragments.first.fields['code'], 'BS');
  });

  test('commitActiveText: Buchseite dann Seite per Leerzeichen', () {
    final bs = parser.commitActiveText(
      committedFragments: const [],
      activeText: 'Buchseite ',
    );
    expect(bs, isNotNull);
    expect(bs!.committedFragments.first.fields['code'], 'BS');

    final page = parser.commitActiveText(
      committedFragments: bs.committedFragments,
      activeText: '42 ',
    );
    expect(page!.committedFragments.first.displayText, 'BS 42');
    expect(page.committedFragments.first.fields['page'], '42');
  });

  test('parst Hefteintrag', () {
    final fragments = parser.parseCompleteLine('Hefteintrag');
    expect(fragments.first.kind, HomeworkFragmentKind.notebook);
  });

  test('commitActiveText: BS dann Seite per Leerzeichen', () {
    final bs = parser.commitActiveText(
      committedFragments: const [],
      activeText: 'BS ',
    );
    expect(bs, isNotNull);
    expect(bs!.committedFragments, hasLength(1));
    expect(bs.committedFragments.first.fields['code'], 'BS');

    final page = parser.commitActiveText(
      committedFragments: bs.committedFragments,
      activeText: '117 ',
    );
    expect(page, isNotNull);
    expect(page!.committedFragments.first.displayText, 'BS 117');
    expect(page.committedFragments.first.fields['page'], '117');
  });

  test('commitActiveText: Aufgabe nach Seite mit Leerzeichen', () {
    var frags = parser.commitActiveText(
      committedFragments: const [],
      activeText: 'BS ',
    )!.committedFragments;

    frags = parser.commitActiveText(
      committedFragments: frags,
      activeText: '117 ',
    )!.committedFragments;

    final done = parser.commitActiveText(
      committedFragments: frags,
      activeText: '3 ',
    );
    expect(done!.committedFragments.first.displayText, 'BS 117/3');
  });

  test('commitActiveText: Seite und Aufgabe kompakt mit Leerzeichen', () {
    var frags = parser.commitActiveText(
      committedFragments: const [],
      activeText: 'BS ',
    )!.committedFragments;

    final done = parser.commitActiveText(
      committedFragments: frags,
      activeText: '117/3 ',
    );
    expect(done!.committedFragments.first.displayText, 'BS 117/3');
  });
}
