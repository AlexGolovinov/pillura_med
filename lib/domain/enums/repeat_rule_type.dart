enum RepeatRuleType { everyDay, everyOtherDay, weekly }

extension RepeatRuleTypeExtension on RepeatRuleType {
  String get label {
    switch (this) {
      case RepeatRuleType.everyDay:
        return 'Каждый день';
      case RepeatRuleType.everyOtherDay:
        return 'Через день';
      case RepeatRuleType.weekly:
        return 'В определенные дни недели';
    }
  }
}
