import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:flutter/material.dart';
import 'package:pillura_med/domain/enums/dosage_type.dart';
import 'package:pillura_med/domain/enums/meal_relation.dart';
import 'package:pillura_med/domain/enums/weekday.dart';

import '../enums/repeat_rule_type.dart';
import 'course_duration.dart';
import 'repeat_rule.dart';

part 'medication.g.dart';

@CopyWith()
class Medication {
  final String id;
  final String userId;
  final String name;
  final double dosage;
  final DosageType dosageType;
  final MealRelation mealRelation;
  final RepeatRule repeatRule;
  final List<TimeOfDay> intakeTime;
  final CourseDuration? durationTaking;
  final bool withBreak;
  final CourseDuration? durationBreak;
  final String? reason;
  final String? symptoms;
  final String? photoUrl;
  final int? color;
  final DateTime startDate;
  final DateTime? endDate;

  Medication({
    required this.id,
    required this.userId,
    required this.name,
    required this.dosage,
    required this.dosageType,
    required this.mealRelation,
    required this.repeatRule,
    required this.intakeTime,
    this.durationTaking,
    required this.withBreak,
    this.durationBreak,
    this.reason,
    this.symptoms,
    this.photoUrl,
    this.color,
    required this.startDate,
    this.endDate,
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
      durationTaking: CourseDuration.fromJson(json['courseDuration'] ?? {}),
      withBreak: json['withBreak'] as bool,
      durationBreak: CourseDuration.fromJson(json['courseDuration'] ?? {}),
      dosage: json['dosage'] as double,
      dosageType: DosageType.values.firstWhere(
        (e) => e.label == json['dosageType'],
      ),
      intakeTime: (json['intakeTime'] as List<dynamic>? ?? [])
          .map((t) => TimeOfDay(hour: t['hour'], minute: t['minute']))
          .toList(),
      // intakeTime: (json['intakeTime'] as List<dynamic>).map((time) {
      //   final parts = (time as String).split(':');
      //   return TimeOfDay(
      //     hour: int.parse(parts[0]),
      //     minute: int.parse(parts[1]),
      //   );
      // }).toList(),
      repeatRule: RepeatRule(
        type: RepeatRuleType.values.firstWhere(
          (e) => e.label == json['repeatRule']['type'],
        ),
        //intervalDays: json['repeatRule']['intervalDays'] as int?,
        weekdays: (json['repeatRule']['weekdays'] as List<dynamic>?)
            ?.map(
              (day) => Weekday.values.firstWhere((e) => e.shortLabel == day),
            )
            .toList(),
      ),
      symptoms: json['symptoms'] as String?,
      photoUrl: json['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'reason': reason,
      'name': name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'mealRelation': mealRelation.name,
      'durationTaking': durationTaking?.toJson(),
      'withBreak': withBreak,
      'durationBreak': durationBreak?.toJson(),
      'dosage': dosage,
      'dosageType': dosageType.name,
      'intakeTime': intakeTime
          .map((t) => {'hour': t.hour, 'minute': t.minute})
          .toList(),
      // 'intakeTime': intakeTime.map((t) => '${t.hour}:${t.minute}').toList(),
      'repeatRule': {
        'type': repeatRule.type.name,
        //'intervalDays': repeatRule.intervalDays,
        'weekdays': repeatRule.weekdays?.map((d) => d.name).toList(),
      },
      'symptoms': symptoms,
      'photoUrl': photoUrl,
    };
  }
}
