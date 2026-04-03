import 'package:equatable/equatable.dart';
import 'package:pillura_med/domain/enums/weekday.dart';
import '../enums/repeat_rule_type.dart';

class RepeatRule extends Equatable {
  final RepeatRuleType type;
  final List<Weekday>? weekdays; // для weekly

  const RepeatRule({required this.type, this.weekdays});

  @override
  List<Object?> get props => [type, weekdays];
}
