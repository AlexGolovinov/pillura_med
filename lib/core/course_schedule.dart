import 'package:pillura_med/domain/entities/course_duration.dart';
import 'package:pillura_med/domain/entities/medication.dart';
import 'package:pillura_med/domain/enums/course_duration_unit.dart';
import 'package:pillura_med/domain/enums/repeat_rule_type.dart';

int intakeDaysTarget(CourseDuration duration) {
  return duration.count *
      (duration.unit == CourseDurationUnit.day
          ? 1
          : duration.unit == CourseDurationUnit.week
          ? 7
          : 30);
}

bool isMedicationIntakeDay(Medication med, DateTime date) {
  final start = DateTime(
    med.startDate.year,
    med.startDate.month,
    med.startDate.day,
  );
  final day = DateTime(date.year, date.month, date.day);
  switch (med.repeatRule.type) {
    case RepeatRuleType.everyDay:
      return true;
    case RepeatRuleType.everyOtherDay:
      return day.difference(start).inDays % 2 == 0;
    case RepeatRuleType.weekly:
      return med.repeatRule.weekdays!.any((w) => w.isoIndex == day.weekday);
  }
}

DateTime? medicationCourseEndDate(Medication med) {
  if (med.durationTaking == null) return null;
  final start = DateTime(
    med.startDate.year,
    med.startDate.month,
    med.startDate.day,
  );
  final target = intakeDaysTarget(med.durationTaking!);
  var found = 0;
  for (var i = 0; i < 366 * 5; i++) {
    final current = start.add(Duration(days: i));
    if (!isMedicationIntakeDay(med, current)) continue;
    found++;
    if (found == target) return current;
  }
  return start;
}

bool isMedicationCourseActive(Medication med, DateTime now) {
  if (med.finishedAt) return false;
  if (med.durationTaking == null) return true;
  final end = medicationCourseEndDate(med);
  if (end == null) return true;
  final today = DateTime(now.year, now.month, now.day);
  return !end.isBefore(today);
}
