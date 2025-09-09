enum CourseDuration { day, week, month }

extension CourseDurationLabel on CourseDuration {
  String get label {
    switch (this) {
      case CourseDuration.day:
        return 'День';
      case CourseDuration.week:
        return 'Неделя';
      case CourseDuration.month:
        return 'Месяц';
    }
  }
}
