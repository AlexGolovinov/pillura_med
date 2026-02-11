enum Weekday {
  monday(1),
  tuesday(2),
  wednesday(3),
  thursday(4),
  friday(5),
  saturday(6),
  sunday(7);

  final int isoIndex;
  const Weekday(this.isoIndex);
}

extension WeekdayLabel on Weekday {
  String get label {
    switch (this) {
      case Weekday.monday:
        return 'Понедельник';
      case Weekday.tuesday:
        return 'Вторник';
      case Weekday.wednesday:
        return 'Среда';
      case Weekday.thursday:
        return 'Четверг';
      case Weekday.friday:
        return 'Пятница';
      case Weekday.saturday:
        return 'Суббота';
      case Weekday.sunday:
        return 'Воскресенье';
    }
  }
}

extension WeekdayShortLabel on Weekday {
  String get shortLabel {
    switch (this) {
      case Weekday.monday:
        return 'Пн';
      case Weekday.tuesday:
        return 'Вт';
      case Weekday.wednesday:
        return 'Ср';
      case Weekday.thursday:
        return 'Чт';
      case Weekday.friday:
        return 'Пт';
      case Weekday.saturday:
        return 'Сб';
      case Weekday.sunday:
        return 'Вс';
    }
  }
}
