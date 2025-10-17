import 'package:flutter/material.dart';
import 'package:pillura_med/domain/enums/dosage_type.dart';
import 'package:pillura_med/domain/enums/course_duration.dart';
import 'package:pillura_med/domain/enums/meal_relation.dart';
import 'package:pillura_med/domain/enums/weekday.dart';

import '../enums/repeat_rule_type.dart';
import 'repeat_rule.dart';

class Medication {
  final String id;
  final String userId;
  final String reason;
  final String name;
  final DateTime startDate;
  final DateTime? endDate;
  final MealRelation mealRelation;
  final CourseDuration? durationTaking;
  final bool withBreak;
  final CourseDuration? durationBreak;
  final double dosage;
  final DosageType dosageType;
  final List<TimeOfDay> intakeTime;
  final RepeatRule repeatRule;
  final String? photoUrl;

  Medication({
    required this.id,
    required this.userId,
    required this.reason,
    required this.name,
    required this.startDate,
    this.endDate,
    required this.mealRelation,
    this.durationTaking,
    required this.withBreak,
    required this.durationBreak,
    required this.dosage,
    required this.dosageType,
    required this.intakeTime,
    required this.repeatRule,
    this.photoUrl,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as String,
      userId: json['userId'] as String,
      reason: json['reason'] as String,
      name: json['name'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      mealRelation: MealRelation.values.firstWhere(
        (e) => e.label == json['mealRelation'],
      ),
      durationTaking: CourseDuration.values.firstWhere(
        (e) => e.label == json['durationTaking'],
      ),
      withBreak: json['withBreak'] as bool,
      durationBreak: CourseDuration.values.firstWhere(
        (e) => e.label == json['durationBreak'],
      ),
      dosage: json['dosage'] as double,
      dosageType: DosageType.values.firstWhere(
        (e) => e.label == json['dosageType'],
      ),
      intakeTime: (json['intakeTime'] as List<dynamic>).map((time) {
        final parts = (time as String).split(':');
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }).toList(),
      repeatRule: RepeatRule(
        type: RepeatRuleType.values.firstWhere(
          (e) => e.label == json['repeatRule']['type'],
        ),
        intervalDays: json['repeatRule']['intervalDays'] as int?,
        weekdays: (json['repeatRule']['weekdays'] as List<dynamic>?)
            ?.map(
              (day) => Weekday.values.firstWhere((e) => e.shortLabel == day),
            )
            .toList(),
      ),
      photoUrl: json['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'reason': reason,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'mealRelation': mealRelation.label,
      'durationTaking': durationTaking?.label,
      'withBreak': withBreak,
      'durationBreak': durationBreak?.label,
      'dosage': dosage,
      'dosageType': dosageType.label,
      'intakeTime': intakeTime.map((t) => '${t.hour}:${t.minute}').toList(),
      'repeatRule': {
        'type': repeatRule.type.label,
        'intervalDays': repeatRule.intervalDays,
        'weekdays': repeatRule.weekdays?.map((d) => d.shortLabel).toList(),
      },
      'photoUrl': photoUrl,
    };
  }
}
