import 'package:equatable/equatable.dart';
import 'package:pillura_med/domain/enums/course_duration_unit.dart';

class CourseDuration extends Equatable {
  final int count;
  final CourseDurationUnit unit;

  const CourseDuration({required this.count, required this.unit});

  factory CourseDuration.fromJson(Map<String, dynamic> json) {
    return CourseDuration(
      count: json['count'] as int,
      unit: CourseDurationUnit.values.firstWhere((e) => e.name == json['unit']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'count': count, 'unit': unit.name};
  }

  @override
  List<Object?> get props => [count, unit];
}
