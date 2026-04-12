class EventListNavigationLogic {
  EventListNavigationLogic({required DateTime startDate})
      : _startDate = _dateOnly(startDate);

  final DateTime _startDate;

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static int _dayNumber(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day)
          .difference(DateTime.utc(1970, 1, 1))
          .inDays;

  DateTime normalize(DateTime date) => _dateOnly(date);

  int indexFromDate(DateTime date) =>
      _dayNumber(date) - _dayNumber(_startDate);

  DateTime dateFromIndex(int index) =>
      _dateOnly(DateTime(_startDate.year, _startDate.month, _startDate.day + index));

  bool shouldNavigate(int? currentIndex, int targetIndex) => currentIndex != targetIndex;

  bool isForward(int fromIndex, int toIndex) => toIndex > fromIndex;
}
