import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pillura_med/domain/enums/dosage_type.dart';
import 'package:pillura_med/domain/enums/meal_relation.dart';

import '../../domain/enums/repeat_rule_type.dart';
import '../../domain/enums/weekday.dart';
import '../providers/medication_provider.dart';
import '../widgets/custom_card.dart';

class AddMedicationPage extends StatefulWidget {
  const AddMedicationPage({super.key});

  @override
  State<AddMedicationPage> createState() => _AddMedicationPageState();
}

class _AddMedicationPageState extends State<AddMedicationPage> {
  DosageType? _selectedDosageType;
  final List<DosageType> _baseDosageType = [DosageType.ml, DosageType.pill];
  DosageType? _extraDosageType; // выбранное из "другое"

  MealRelation? _selectedMealRelation = MealRelation.regardless;
  final List<MealRelation> _mealRelations = MealRelation.values;

  RepeatRuleType? _selected = null;
  final Set<int> _days = {}; // выбранные дни недели
  String _dropdownKey = '1';

  @override
  Widget build(BuildContext context) {
    final otherDosageType = DosageType.values
        .where((e) => !_baseDosageType.contains(e) && _extraDosageType != e)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text('Добавить лекарство')),
      body: SafeArea(
        child: FormField(
          builder: (field) {
            return Padding(
              padding: EdgeInsets.only(left: 8, right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16),
                  Text(
                    "Название лекарства",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 8),
                  SizedBox(
                    height: 41,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Введите название лекарства',
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    "Сколько принять",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 8),
                  SizedBox(
                    height: 41,
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Введите количество',
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // фиксированные основные
                      ..._baseDosageType.map(
                        (e) => GestureDetector(
                          onTap: () => setState(() {
                            _selectedDosageType = e;
                            _extraDosageType = null;
                          }),
                          child: customCard(
                            title: e.label,
                            isSelected: _selectedDosageType == e,
                          ),
                        ),
                      ),

                      // если выбрано из "другое" — показываем его как основное
                      if (_extraDosageType != null)
                        GestureDetector(
                          onTap: () => setState(() {
                            _selectedDosageType = _extraDosageType;
                          }),
                          child: customCard(
                            title: _extraDosageType!.label,
                            isSelected: _selectedDosageType == _extraDosageType,
                          ),
                        ),

                      // сама кнопка "другое..."
                      PopupMenuButton<DosageType>(
                        offset: Offset(10, 41),
                        onSelected: (value) {
                          setState(() {
                            _extraDosageType = value; // сохраняем новый
                            _selectedDosageType = value;
                          });
                        },
                        itemBuilder: (_) => otherDosageType
                            .map(
                              (e) =>
                                  PopupMenuItem(value: e, child: Text(e.label)),
                            )
                            .toList(),
                        child: customCard(
                          title: 'другое...',
                          isSelected: false,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  Text(
                    "Принимать лекарство",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _mealRelations
                        .map(
                          (e) => GestureDetector(
                            onTap: () => setState(() {
                              _selectedMealRelation = e;
                            }),
                            child: customCard(
                              title: e.label,
                              isSelected: _selectedMealRelation == e,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  SizedBox(height: 24),
                  Text(
                    "Интервал приёма лекарства",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 8),
                  dropdownInterval(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget dropdownInterval() {
    return DropdownMenu<RepeatRuleType>(
      alignmentOffset: Offset(10, 8),
      key: Key(_dropdownKey), // сброс состояния при изменении выбора
      hintText: 'Выберите интервал',
      menuStyle: MenuStyle(
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
      initialSelection: _selected,
      onSelected: (value) {
        if (value != RepeatRuleType.weekly) {
          // только обычные варианты кликаются
          setState(() {
            _selected = value;
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
                  fontWeight: _selected == RepeatRuleType.everyDay
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
                  fontWeight: _selected == RepeatRuleType.everyOtherDay
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
                  fontWeight: _selected == RepeatRuleType.weekly
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
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
                            _selected = null;
                          }
                        } else {
                          _days.add(e.index);
                          _selected = RepeatRuleType.weekly;
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
            ],
          ),
        ),
      ],
    );
  }
}
