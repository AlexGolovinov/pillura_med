import 'package:pillura_med/domain/enums/weekday.dart';
import '../enums/repeat_rule_type.dart';

class RepeatRule {
  final RepeatRuleType type;
  final int? intervalDays; // для interval
  final List<Weekday>? weekdays; // для weekly

  RepeatRule({required this.type, this.intervalDays, this.weekdays});
}
