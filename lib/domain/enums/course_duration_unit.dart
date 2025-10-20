enum CourseDurationUnit { day, week, month }

extension CourseDurationUnitLabel on CourseDurationUnit {
  String get label {
    switch (this) {
      case CourseDurationUnit.day:
        return 'День';
      case CourseDurationUnit.week:
        return 'Неделя';
      case CourseDurationUnit.month:
        return 'Месяц';
    }
  }
}
