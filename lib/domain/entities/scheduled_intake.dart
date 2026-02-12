class ScheduledIntake {
  final bool? isTaken;
  final DateTime scheduledDateTime;

  ScheduledIntake({this.isTaken, required this.scheduledDateTime});

  factory ScheduledIntake.fromJson(Map<String, dynamic> json) {
    return ScheduledIntake(
      isTaken: json['isTaken'] as bool?,
      scheduledDateTime: DateTime.parse(json['scheduledDateTime'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isTaken': isTaken,
      'scheduledDateTime': scheduledDateTime.toIso8601String(),
    };
  }
}
