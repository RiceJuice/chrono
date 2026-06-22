import 'package:chronoapp/core/time/app_date_time.dart';

enum MealPeriod { lunch, dinner }

/// Grob zeitenbasierte Einordnung: vor 15:00 Mittag, ab 15:00 Abendessen.
MealPeriod resolveMealPeriod(DateTime startTime) {
  final hour = AppDateTime.toLocal(startTime).hour;
  return hour < 15 ? MealPeriod.lunch : MealPeriod.dinner;
}

extension MealPeriodDisplay on MealPeriod {
  String get label => switch (this) {
        MealPeriod.lunch => 'Mittag',
        MealPeriod.dinner => 'Abendessen',
      };
}
