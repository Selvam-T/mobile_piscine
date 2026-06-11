class DiaryDateFormatter {
  const DiaryDateFormatter._();

  static String day(DateTime date) {
    return '${date.day}';
  }

  static String month(DateTime date) {
    const List<String> months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[date.month - 1];
  }

  static String weekday(DateTime date) {
    const List<String> weekdays = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return weekdays[date.weekday - 1];
  }

  static String year(DateTime date) {
    return '${date.year}';
  }

  static String fullDate(DateTime date) {
    return '${weekday(date)}, ${month(date)} ${day(date)}, ${year(date)}';
  }
}
