import 'package:flutter/material.dart';

import '../../domain/enums/repeat_rule_type.dart';
import '../../domain/enums/weekday.dart';
import 'custom_card.dart';

class IntervalWidget extends StatefulWidget {
  void Function(RepeatRuleType?)? onSaved;
  IntervalWidget({super.key, this.onSaved});

  @override
  State<IntervalWidget> createState() => _IntervalWidgetState();
}

class _IntervalWidgetState extends State<IntervalWidget> {
  final Set<int> _days = {}; // выбранные дни недели
  String _dropdownKey = '1';
  @override
  Widget build(BuildContext context) {
    return FormField<RepeatRuleType?>(
      validator: (value) {
        if (value == null) {
          return 'Выберите интервал приема лекарства';
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onSaved: widget.onSaved,
      onReset: () {
        setState(() {
          _days.clear();
          _dropdownKey = UniqueKey().toString();
        });
      },
      builder: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownMenu<RepeatRuleType?>(
            initialSelection: state.value,
            menuHeight: 300,
            inputDecorationTheme: InputDecorationTheme(
              isDense: true,
              constraints: BoxConstraints.tight(const Size.fromHeight(41)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            alignmentOffset: Offset(0, 8),
            key: Key(_dropdownKey), // сброс состояния при изменении выбора
            hintText: 'Выберите интервал',
            menuStyle: MenuStyle(
              padding: WidgetStateProperty.all(EdgeInsets.all(8)),
              backgroundColor: WidgetStateProperty.all(Colors.white),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(
                    color: Colors.grey, // цвет бордера
                    width: 1, // толщина
                  ),
                ),
              ),

              elevation: WidgetStateProperty.all(
                0,
              ), // убрать тень, если нужен только бордер
            ),
            width: double.infinity,
            onSelected: (value) {
              if (value != RepeatRuleType.weekly) {
                // только обычные варианты кликаются
                setState(() {
                  state.didChange(value);
                  _days.clear();
                });
              }
              // если weekly — игнорируем здесь, выбор будет через дни
            },
            dropdownMenuEntries: [
              DropdownMenuEntry(
                value: RepeatRuleType.everyDay,
                label: RepeatRuleType.everyDay.label,
                style: MenuItemButton.styleFrom(
                  backgroundColor: Colors.white, // фон при выборе
                  foregroundColor: Colors.black,
                ),
                labelWidget: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      RepeatRuleType.everyDay.label,
                      style: TextStyle(
                        fontWeight: state.value == RepeatRuleType.everyDay
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    const Divider(thickness: 1.5),
                  ],
                ),
              ),
              DropdownMenuEntry(
                value: RepeatRuleType.everyOtherDay,
                label: RepeatRuleType.everyOtherDay.label,
                style: MenuItemButton.styleFrom(
                  backgroundColor: Colors.white, // фон при выборе
                  foregroundColor: Colors.black,
                ),

                labelWidget: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      RepeatRuleType.everyOtherDay.label,
                      style: TextStyle(
                        fontWeight: state.value == RepeatRuleType.everyOtherDay
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    const Divider(thickness: 1.5),
                  ],
                ),
              ),
              // weekly — НЕ кликабельный, только контейнер
              DropdownMenuEntry(
                value: RepeatRuleType.weekly,
                label: RepeatRuleType.weekly.label,
                enabled: false, // 🔑 теперь по заголовку клик не работает
                labelWidget: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      RepeatRuleType.weekly.label,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: state.value == RepeatRuleType.weekly
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 50,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 10,
                        children: Weekday.values.map((e) {
                          final isSelected = _days.contains(e.index);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _days.remove(e.index);
                                  if (_days.isEmpty) {
                                    _dropdownKey = UniqueKey()
                                        .toString(); // сброс состояния DropdownMenu
                                    state.didChange(null);
                                  }
                                } else {
                                  _days.add(e.index);
                                  state.didChange(RepeatRuleType.weekly);
                                }
                              });
                            },
                            child: customCard(
                              title: e.shortLabel,
                              isSelected: isSelected,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (state.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 16),
              child: Text(
                state.errorText!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
