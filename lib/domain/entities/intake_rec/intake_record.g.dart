// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intake_record.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$IntakeRecordCWProxy {
  IntakeRecord id(String? id);

  IntakeRecord isTaken(bool? isTaken);

  IntakeRecord scheduledDateTime(DateTime scheduledDateTime);

  IntakeRecord medicationId(String? medicationId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `IntakeRecord(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// IntakeRecord(...).copyWith(id: 12, name: "My name")
  /// ````
  IntakeRecord call({
    String? id,
    bool? isTaken,
    DateTime scheduledDateTime,
    String? medicationId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfIntakeRecord.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfIntakeRecord.copyWith.fieldName(...)`
class _$IntakeRecordCWProxyImpl implements _$IntakeRecordCWProxy {
  const _$IntakeRecordCWProxyImpl(this._value);

  final IntakeRecord _value;

  @override
  IntakeRecord id(String? id) => this(id: id);

  @override
  IntakeRecord isTaken(bool? isTaken) => this(isTaken: isTaken);

  @override
  IntakeRecord scheduledDateTime(DateTime scheduledDateTime) =>
      this(scheduledDateTime: scheduledDateTime);

  @override
  IntakeRecord medicationId(String? medicationId) =>
      this(medicationId: medicationId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `IntakeRecord(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// IntakeRecord(...).copyWith(id: 12, name: "My name")
  /// ````
  IntakeRecord call({
    Object? id = const $CopyWithPlaceholder(),
    Object? isTaken = const $CopyWithPlaceholder(),
    Object? scheduledDateTime = const $CopyWithPlaceholder(),
    Object? medicationId = const $CopyWithPlaceholder(),
  }) {
    return IntakeRecord(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String?,
      isTaken: isTaken == const $CopyWithPlaceholder()
          ? _value.isTaken
          // ignore: cast_nullable_to_non_nullable
          : isTaken as bool?,
      scheduledDateTime: scheduledDateTime == const $CopyWithPlaceholder()
          ? _value.scheduledDateTime
          // ignore: cast_nullable_to_non_nullable
          : scheduledDateTime as DateTime,
      medicationId: medicationId == const $CopyWithPlaceholder()
          ? _value.medicationId
          // ignore: cast_nullable_to_non_nullable
          : medicationId as String?,
    );
  }
}

extension $IntakeRecordCopyWith on IntakeRecord {
  /// Returns a callable class that can be used as follows: `instanceOfIntakeRecord.copyWith(...)` or like so:`instanceOfIntakeRecord.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$IntakeRecordCWProxy get copyWith => _$IntakeRecordCWProxyImpl(this);
}
