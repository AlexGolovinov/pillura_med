import 'package:pillura_med/domain/enums/course_duration_unit.dart';

class CourseDuration {
  final int count;
  final CourseDurationUnit unit;

  CourseDuration({required this.count, required this.unit});

  factory CourseDuration.fromJson(Map<String, dynamic> json) {
    return CourseDuration(
      count: json['count'] as int,
      unit: CourseDurationUnit.values.firstWhere(
        (e) => e.label == json['duration'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {'count': count, 'unit': unit.name};
  }
}
