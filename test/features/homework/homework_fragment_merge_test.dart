import 'package:chronoapp/features/homework/domain/homework_fragment_merge.dart';
import 'package:chronoapp/features/homework/domain/models/homework_contribution.dart';
import 'package:chronoapp/features/homework/domain/models/homework_fragment.dart';
import 'package:flutter_test/flutter_test.dart';

HomeworkFragment _book(String code, String page, [String? exercise]) {
  return HomeworkFragment(
    kind: HomeworkFragmentKind.book,
    canonicalKey: exercise == null ? 'book:$code:$page' : 'book:$code:$page:$exercise',
    displayText: exercise == null ? '$code $page' : '$code $page/$exercise',
    chipColorKey: 'book',
    fields: {
      'code': code,
      'page': page,
      if (exercise != null) 'exercise': exercise,
    },
  );
}

HomeworkContribution _contribution({
  required String profileId,
  required String subjectId,
  required List<HomeworkFragment> fragments,
}) {
  return HomeworkContribution(
    id: 'c-$profileId',
    profileId: profileId,
    className: '10a',
    schooltrack: 'G8',
    subjectId: subjectId,
    lessonDate: DateTime(2026, 6, 27),
    fragments: fragments,
    fragmentHashes: fragments.map((f) => f.canonicalKey).toList(),
    createdAt: DateTime(2026, 6, 27, 12),
    updatedAt: DateTime(2026, 6, 27, 12),
  );
}

void main() {
  test('mergeClassFragments vereint ohne Duplikate', () {
    final a = _contribution(
      profileId: 'u1',
      subjectId: 'latin',
      fragments: [_book('BS', '117', '3')],
    );
    final b = _contribution(
      profileId: 'u2',
      subjectId: 'math',
      fragments: [_book('TB', '42', '1')],
    );

    final merged = mergeClassFragments([a, b]);
    expect(merged, hasLength(2));
  });

  test('computeDeltaToUpload liefert nur neue Fragmente', () {
    final peer = _contribution(
      profileId: 'u1',
      subjectId: 'latin',
      fragments: [_book('BS', '117', '3')],
    );
    final local = [_book('BS', '117', '3'), _book('TB', '10', '2')];

    final delta = computeDeltaToUpload(
      localFragments: local,
      classContributions: [peer],
      profileId: 'u2',
    );

    expect(delta, hasLength(1));
    expect(delta.first.fields['code'], 'TB');
  });
}
