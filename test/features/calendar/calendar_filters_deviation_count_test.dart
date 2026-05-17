import 'package:chronoapp/features/calendar/domain/filter/calendar_filters_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalendarFiltersState.deviationCategoryCount', () {
    test('counts choir once even with multiple selections', () {
      const state = CalendarFiltersState(
        choirs: ['Chor A', 'Chor B'],
        defaultChoirs: ['Chor A'],
        isChoirExplicit: true,
      );

      expect(state.deviationCategoryCount, 1);
    });

    test('counts choir and diet as two categories', () {
      const state = CalendarFiltersState(
        choirs: ['Anderes Ensemble'],
        defaultChoirs: ['Standardchor'],
        diets: ['Vegan'],
        defaultDiets: ['Normal'],
      );

      expect(state.deviationCategoryCount, 2);
    });

    test('returns zero when selections match defaults', () {
      const state = CalendarFiltersState(
        choirs: ['Standardchor'],
        defaultChoirs: ['Standardchor'],
        diets: ['Normal'],
        defaultDiets: ['Normal'],
      );

      expect(state.deviationCategoryCount, 0);
    });
  });
}
