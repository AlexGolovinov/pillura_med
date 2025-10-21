// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medication.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MedicationCWProxy {
  Medication id(String id);

  Medication userId(String userId);

  Medication name(String name);

  Medication dosage(double dosage);

  Medication dosageType(DosageType dosageType);

  Medication mealRelation(MealRelation mealRelation);

  Medication repeatRule(RepeatRule repeatRule);

  Medication intakeTime(List<TimeOfDay> intakeTime);

  Medication durationTaking(CourseDuration? durationTaking);

  Medication withBreak(bool withBreak);

  Medication durationBreak(CourseDuration? durationBreak);

  Medication reason(String? reason);

  Medication symptoms(String? symptoms);

  Medication photoUrl(String? photoUrl);

  Medication color(int? color);

  Medication startDate(DateTime startDate);

  Medication endDate(DateTime? endDate);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Medication(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Medication(...).copyWith(id: 12, name: "My name")
  /// ````
  Medication call({
    String id,
    String userId,
    String name,
    double dosage,
    DosageType dosageType,
    MealRelation mealRelation,
    RepeatRule repeatRule,
    List<TimeOfDay> intakeTime,
    CourseDuration? durationTaking,
    bool withBreak,
    CourseDuration? durationBreak,
    String? reason,
    String? symptoms,
    String? photoUrl,
    int? color,
    DateTime startDate,
    DateTime? endDate,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMedication.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMedication.copyWith.fieldName(...)`
class _$MedicationCWProxyImpl implements _$MedicationCWProxy {
  const _$MedicationCWProxyImpl(this._value);

  final Medication _value;

  @override
  Medication id(String id) => this(id: id);

  @override
  Medication userId(String userId) => this(userId: userId);

  @override
  Medication name(String name) => this(name: name);

  @override
  Medication dosage(double dosage) => this(dosage: dosage);

  @override
  Medication dosageType(DosageType dosageType) => this(dosageType: dosageType);

  @override
  Medication mealRelation(MealRelation mealRelation) =>
      this(mealRelation: mealRelation);

  @override
  Medication repeatRule(RepeatRule repeatRule) => this(repeatRule: repeatRule);

  @override
  Medication intakeTime(List<TimeOfDay> intakeTime) =>
      this(intakeTime: intakeTime);

  @override
  Medication durationTaking(CourseDuration? durationTaking) =>
      this(durationTaking: durationTaking);

  @override
  Medication withBreak(bool withBreak) => this(withBreak: withBreak);

  @override
  Medication durationBreak(CourseDuration? durationBreak) =>
      this(durationBreak: durationBreak);

  @override
  Medication reason(String? reason) => this(reason: reason);

  @override
  Medication symptoms(String? symptoms) => this(symptoms: symptoms);

  @override
  Medication photoUrl(String? photoUrl) => this(photoUrl: photoUrl);

  @override
  Medication color(int? color) => this(color: color);

  @override
  Medication startDate(DateTime startDate) => this(startDate: startDate);

  @override
  Medication endDate(DateTime? endDate) => this(endDate: endDate);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Medication(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Medication(...).copyWith(id: 12, name: "My name")
  /// ````
  Medication call({
    Object? id = const $CopyWithPlaceholder(),
    Object? userId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? dosage = const $CopyWithPlaceholder(),
    Object? dosageType = const $CopyWithPlaceholder(),
    Object? mealRelation = const $CopyWithPlaceholder(),
    Object? repeatRule = const $CopyWithPlaceholder(),
    Object? intakeTime = const $CopyWithPlaceholder(),
    Object? durationTaking = const $CopyWithPlaceholder(),
    Object? withBreak = const $CopyWithPlaceholder(),
    Object? durationBreak = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? symptoms = const $CopyWithPlaceholder(),
    Object? photoUrl = const $CopyWithPlaceholder(),
    Object? color = const $CopyWithPlaceholder(),
    Object? startDate = const $CopyWithPlaceholder(),
    Object? endDate = const $CopyWithPlaceholder(),
  }) {
    return Medication(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      userId: userId == const $CopyWithPlaceholder()
          ? _value.userId
          // ignore: cast_nullable_to_non_nullable
          : userId as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      dosage: dosage == const $CopyWithPlaceholder()
          ? _value.dosage
          // ignore: cast_nullable_to_non_nullable
          : dosage as double,
      dosageType: dosageType == const $CopyWithPlaceholder()
          ? _value.dosageType
          // ignore: cast_nullable_to_non_nullable
          : dosageType as DosageType,
      mealRelation: mealRelation == const $CopyWithPlaceholder()
          ? _value.mealRelation
          // ignore: cast_nullable_to_non_nullable
          : mealRelation as MealRelation,
      repeatRule: repeatRule == const $CopyWithPlaceholder()
          ? _value.repeatRule
          // ignore: cast_nullable_to_non_nullable
          : repeatRule as RepeatRule,
      intakeTime: intakeTime == const $CopyWithPlaceholder()
          ? _value.intakeTime
          // ignore: cast_nullable_to_non_nullable
          : intakeTime as List<TimeOfDay>,
      durationTaking: durationTaking == const $CopyWithPlaceholder()
          ? _value.durationTaking
          // ignore: cast_nullable_to_non_nullable
          : durationTaking as CourseDuration?,
      withBreak: withBreak == const $CopyWithPlaceholder()
          ? _value.withBreak
          // ignore: cast_nullable_to_non_nullable
          : withBreak as bool,
      durationBreak: durationBreak == const $CopyWithPlaceholder()
          ? _value.durationBreak
          // ignore: cast_nullable_to_non_nullable
          : durationBreak as CourseDuration?,
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String?,
      symptoms: symptoms == const $CopyWithPlaceholder()
          ? _value.symptoms
          // ignore: cast_nullable_to_non_nullable
          : symptoms as String?,
      photoUrl: photoUrl == const $CopyWithPlaceholder()
          ? _value.photoUrl
          // ignore: cast_nullable_to_non_nullable
          : photoUrl as String?,
      color: color == const $CopyWithPlaceholder()
          ? _value.color
          // ignore: cast_nullable_to_non_nullable
          : color as int?,
      startDate: startDate == const $CopyWithPlaceholder()
          ? _value.startDate
          // ignore: cast_nullable_to_non_nullable
          : startDate as DateTime,
      endDate: endDate == const $CopyWithPlaceholder()
          ? _value.endDate
          // ignore: cast_nullable_to_non_nullable
          : endDate as DateTime?,
    );
  }
}

extension $MedicationCopyWith on Medication {
  /// Returns a callable class that can be used as follows: `instanceOfMedication.copyWith(...)` or like so:`instanceOfMedication.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MedicationCWProxy get copyWith => _$MedicationCWProxyImpl(this);
}
