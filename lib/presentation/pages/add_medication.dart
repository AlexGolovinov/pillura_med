import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pillura_med/domain/enums/dosage_type.dart';
import 'package:pillura_med/domain/enums/meal_relation.dart';
import 'package:pillura_med/presentation/widgets/dosage_widget.dart';
import 'package:pillura_med/presentation/widgets/interval_widget.dart';
import 'package:pillura_med/presentation/widgets/input_block.dart';
import 'package:pillura_med/presentation/widgets/meal_relation_widget.dart';

import '../../domain/entities/course_duration.dart';
import '../../domain/entities/repeat_rule.dart';
import '../widgets/automatic_interval_widget.dart';
import '../widgets/course_duration_widget.dart';
import '../widgets/manual_intake_widget.dart';

class AddMedicationPage extends StatefulWidget {
  const AddMedicationPage({super.key});

  @override
  State<AddMedicationPage> createState() => _AddMedicationPageState();
}

class _AddMedicationPageState extends State<AddMedicationPage> {
  final _formKey = GlobalKey<FormState>();

  String? _name;
  int? _dosage;
  DosageType? _selectedDosageType;
  MealRelation? _selectedMealRelation;
  RepeatRule? _selectedInterval;
  List<TimeOfDay?>? intakeTime;

  CourseDuration? durationTaking;
  CourseDuration? durationBreak;
  String? reason;
  String? symptoms;
  Color? selectedColor;

  bool switchAuto = false;
  bool switchWithBreak = false;
  int? selectedPicker;

  void _addMedicine() {
    if (!switchWithBreak) {
      durationBreak = null;
    }
    log('Не прошел валидацию');
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      log('Название: $_name');
      log('Количество: $_dosage');
      log('Тип дозировки: $_selectedDosageType');
      log('Прием относительно еды: $_selectedMealRelation');
      log('Интервал приема: $_selectedInterval');
      log('Время приема: $intakeTime');
      log('Длительность приема: ${durationTaking?.toJson()}');
      log('Длительность перерыва: ${durationBreak?.toJson()}');
      log('Причина приема: $reason');
      log('Симптомы: $symptoms');
      log('Цвет: ${selectedColor?.toARGB32()}');
      //_formKey.currentState!.reset();
      // Тут можно локально сохранить данные или вызвать колбек
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Сохранено ✅')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Добавить лекарство')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(left: 8, right: 8, bottom: 16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16),
                    InputBlock(
                      title: 'Название лекарства',
                      hintText: 'Введите название лекарства',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Введите название лекарства';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _name = value;
                      },
                    ),
                    SizedBox(height: 24),
                    DosageWidget(
                      onSavedType: (value) {
                        _selectedDosageType = value;
                      },
                      onSavedDosage: (value) {
                        _dosage = value;
                      },
                    ),
                    SizedBox(height: 24),
                    MealRelationWidget(
                      onSaved: (value) {
                        _selectedMealRelation = value;
                      },
                    ),
                    SizedBox(height: 24),
                    Text(
                      "Интервал приёма лекарства",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    IntervalWidget(
                      onSaved: (value) {
                        _selectedInterval = value;
                      },
                    ),
                    SizedBox(height: 24),
                    Text(
                      "Время приема",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Ручной ввод',
                          style: !switchAuto
                              ? TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                )
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8, right: 8),
                          child: FlutterSwitch(
                            height: 41,
                            inactiveIcon: Icon(Icons.edit),
                            inactiveColor: Color(0xFFE3E7FF),
                            activeColor: Color(0xFFE3E7FF),
                            activeIcon: Icon(Icons.computer),
                            value: switchAuto,
                            onToggle: (bool value) {
                              setState(() {
                                switchAuto = value;
                              });
                            },
                          ),
                        ),
                        Text(
                          'Автоматический рассчет',
                          style: switchAuto
                              ? TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                )
                              : null,
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    switchAuto == false
                        ? ManualIntakeWidget(
                            onSaved: (newValue) {
                              intakeTime = newValue;
                            },
                          )
                        : AutomaticIntervalWidget(
                            onSaved: (newValue) {
                              intakeTime = newValue;
                            },
                          ),

                    SizedBox(height: 24),
                    ExpansionTile(
                      maintainState: true,
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      collapsedBackgroundColor: Color(0xFFF5F7FF),
                      backgroundColor: Color(0xFFF5F7FF),
                      collapsedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      childrenPadding: EdgeInsets.only(left: 16, right: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      subtitle: Text(
                        'Они не обязательны, но могут быть полезны',
                      ),
                      title: Text(
                        'Дополнительные функции',
                        style: GoogleFonts.openSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      children: [
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Разовый прием',
                              style: !switchWithBreak
                                  ? TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                    )
                                  : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8, right: 8),
                              child: FlutterSwitch(
                                height: 41,
                                activeToggleColor: Colors.indigoAccent,
                                inactiveToggleColor: Colors.indigoAccent,
                                inactiveColor: Color(0xFFE3E7FF),
                                activeColor: Color(0xFFE3E7FF),
                                value: switchWithBreak,
                                onToggle: (bool value) {
                                  setState(() {
                                    switchWithBreak = value;
                                  });
                                },
                              ),
                            ),
                            Text(
                              'С перерывом',
                              style: switchWithBreak
                                  ? TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                    )
                                  : null,
                            ),
                            SizedBox(width: 8),
                            showInfoAboutBreak(context),
                          ],
                        ),
                        SizedBox(height: 24),
                        CourseDurationWidget(
                          title: 'Длительность приема',
                          withBreak: switchWithBreak,
                          onSaved: (courseIntake) {
                            durationTaking = courseIntake;
                          },
                        ),
                        switchWithBreak
                            ? Column(
                                children: [
                                  SizedBox(height: 24),
                                  CourseDurationWidget(
                                    title: 'Длительность перерыва',
                                    withBreak: switchWithBreak,
                                    onSaved: (courseBreak) {
                                      durationBreak = courseBreak;
                                    },
                                  ),
                                ],
                              )
                            : Container(),
                        SizedBox(height: 24),
                        Row(
                          children: [
                            Text(
                              'Причина приема (болезнь или)',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Информация'),
                                    content: Text(
                                      'Приложение поможет вести историю и строить статистику, чтобы тебе было легче просматривать ее в будущем',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Понятно'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Icon(
                                Icons.info_outline,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        SizedBox(
                          height: 41,
                          child: TextFormField(
                            decoration: InputDecoration(
                              hintText: 'Грипп, ангина...',
                            ),
                            onSaved: (value) {
                              reason = value;
                            },
                          ),
                        ),
                        SizedBox(height: 24),
                        InputBlock(
                          title: 'Симптомы(с чем помогает это лекарство)',
                          hintText: 'боль в горле, кашель...',
                          onSaved: (value) {
                            symptoms = value;
                          },
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Выбрать цвет для боковой полосочки',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: 8),
                        colorPicker(),
                        SizedBox(height: 8),
                      ],
                    ),

                    SizedBox(height: 24),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF202D85),
                        minimumSize: Size(double.infinity, 41),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        _addMedicine();
                      },
                      child: Text(
                        'Добавить',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium!.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget colorPicker() {
    final colors = [
      Color(0xFFFAF7A6),
      Color(0xFFE4F3AB),
      Color(0xFFE8EFFB),
      Color(0xFFDDEFFF),
      Color(0xFFD5D4FE),
      Color(0xFFF1E1FF),
      Color(0xFFE3E7FF),
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
    ];

    return SizedBox(
      height: 41,
      width: double.infinity,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (selectedPicker == index) {
                    selectedPicker = null;
                    selectedColor = null;
                  } else {
                    selectedPicker = index;
                    selectedColor = colors[index];
                  }
                });
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 41,
                    height: 41,
                    decoration: BoxDecoration(
                      color: colors[index],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black12),
                    ),
                  ),
                  if (selectedPicker == index)
                    const Icon(Icons.check, color: Colors.black, size: 28),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  GestureDetector showInfoAboutBreak(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Информация'),
            content: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Разовый прием: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                        ' принимаю лекарство непрерывно (например, 7 дней или 1 месяц)\n\n',
                  ),
                  TextSpan(
                    text: 'С перерывом: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                        'принимаю курсами (например, 5 дней приём → 2 дня перерыв) Когда закончится прием вы самостоятельно нажмете завершить. А так будет повторятся всегда 5 дней прием, 2 перерыв',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Понятно'),
              ),
            ],
          ),
        );
      },
      child: Icon(Icons.info_outline, color: Colors.grey),
    );
  }
}
