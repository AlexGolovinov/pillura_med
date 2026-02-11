import 'package:copy_with_extension/copy_with_extension.dart';
part 'intake_record.g.dart';

@CopyWith()
class IntakeRecord {
  final String? id;
  final String? medicationId;
  final DateTime scheduledDateTime;
  final bool? isTaken;

  IntakeRecord({
    this.id,
    this.isTaken,
    required this.scheduledDateTime,
    this.medicationId,
  });

  factory IntakeRecord.fromJson(Map<String, dynamic> json) {
    return IntakeRecord(
      id: json['id'] as String?,
      isTaken: json['isTaken'] as bool?,
      scheduledDateTime: DateTime.parse(json['scheduledDateTime'] as String),
      medicationId: json['medicationId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isTaken': isTaken,
      'scheduledDateTime': scheduledDateTime.toIso8601String(),
      'medicationId': medicationId,
    };
  }
}
