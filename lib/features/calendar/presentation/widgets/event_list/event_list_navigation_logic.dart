class EventListNavigationLogic {
  EventListNavigationLogic({required DateTime startDate})
      : _startDate = _dateOnly(startDate);

  static const transitionDurationMs = 300;
  final DateTime _startDate;

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime normalize(DateTime date) => _dateOnly(date);

  int indexFromDate(DateTime date) => _dateOnly(date).difference(_startDate).inDays;

  DateTime dateFromIndex(int index) => _dateOnly(_startDate.add(Duration(days: index)));

  bool shouldNavigate(int? currentIndex, int targetIndex) => currentIndex != targetIndex;

  bool isForward(int fromIndex, int toIndex) => toIndex > fromIndex;
}
