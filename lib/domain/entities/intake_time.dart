import 'package:flutter/material.dart';

class IntakeTime {
  final bool? isTaken;
  final TimeOfDay time;

  IntakeTime({this.isTaken, required this.time});

  factory IntakeTime.fromJson(Map<String, dynamic> json) {
    return IntakeTime(
      isTaken: json['isTaken'] as bool?,
      time: TimeOfDay(hour: json['hour'] as int, minute: json['minute'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {'isTaken': isTaken, 'hour': time.hour, 'minute': time.minute};
  }
}
