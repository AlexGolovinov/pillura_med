import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:pillura_med/core/extension/theme_extension.dart';

import '../../domain/entities/intake_rec/intake_record.dart';

class MedicationCard extends StatelessWidget {
  final String title;
  final String dosage;
  final String dosageType;
  final DateTime startDate;
  final List<IntakeRecord> intakeRecords;
  final String courseInfo;
  final Color? color;
  final VoidCallback deleteMedication;
  final Function(IntakeRecord) onTake;
  final Function(IntakeRecord) onSkip;
  const MedicationCard({
    super.key,
    required this.title,
    required this.dosage,
    required this.dosageType,
    required this.startDate,
    required this.intakeRecords,
    required this.deleteMedication,
    required this.courseInfo,
    this.color,
    required this.onTake,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    deleteMedicationDialog() {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Удалить лекарство?'),
            content: Text(
              'Вы уверены, что хотите удалить $title лекарство из списка?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Закрыть диалог
                },
                child: Text('Отмена'),
              ),
              TextButton(
                onPressed: () {
                  deleteMedication();
                  Navigator.of(context).pop(); // Закрыть диалог
                },
                child: Text('Удалить', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      );
    }

    // Фильтруем записи на сегодня
    final today = DateTime.now();
    final todayRecords = intakeRecords.where((record) {
      final recordDate = record.scheduledDateTime;
      return recordDate.year == today.year &&
          recordDate.month == today.month &&
          recordDate.day == today.day;
    }).toList();

    int total = todayRecords.length;
    int isTaken = todayRecords.where((record) => record.isTaken == true).length;
    int isNotTaken = todayRecords
        .where((record) => record.isTaken == false)
        .length;
    return Slidable(
      key: UniqueKey(),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.25,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200], //const Color(0xFFF4F4F4),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          topLeft: Radius.circular(10),
                        ),
                      ),
                      alignment: Alignment.center,
                      //margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                        child: const Icon(
                          Icons.check,
                          size: 28,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200], //const Color(0xFFF4F4F4),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          topLeft: Radius.circular(10),
                        ),
                      ),
                      alignment: Alignment.center,
                      //margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 28,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      deleteMedicationDialog();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200], //const Color(0xFFF4F4F4),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          topLeft: Radius.circular(10),
                        ),
                      ),
                      alignment: Alignment.center,
                      //margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                        child: const Icon(
                          Icons.delete_forever_rounded,
                          size: 28,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Container(
          height: 130,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: Row(
            children: [
              Container(
                width: 19,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    topLeft: Radius.circular(10),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Spacer(),
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            color: const Color(0xFFE8EFFB),

                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              child: Text(
                                'по $dosage $dosageType',
                                style: Theme.of(context).textTheme.bodyMedium!
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          if (total > 4)
                            Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                                side: BorderSide(color: Colors.blue),
                              ),
                              shadowColor: Colors.transparent,
                              color: Colors.white,

                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      '$isNotTaken',
                                      style: context.textTheme.bodyMedium
                                          ?.copyWith(color: Colors.red),
                                    ),
                                    Text(
                                      '/$isTaken',
                                      style: context.textTheme.bodyMedium
                                          ?.copyWith(color: Colors.green),
                                    ),
                                    Text(
                                      '/$total',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        'c ${startDate.day} ${getMonthName(startDate.month)} - $courseInfo',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(todayRecords.length, (index) {
                            final record = todayRecords[index];
                            final time = TimeOfDay.fromDateTime(
                              record.scheduledDateTime,
                            );
                            return GestureDetector(
                              onTap: () {
                                showIntakeDialog(
                                  title,
                                  record,
                                  context,
                                  onTake,
                                  onSkip,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: record.isTaken == null
                                        ? Colors.white
                                        : record.isTaken == true
                                        ? const Color(0xFFC6D649)
                                        : Colors.redAccent[100],
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                  child: Text(
                                    '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      // color: !isPast
                                      //     ? Colors.black
                                      //     : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String getMonthName(int month) {
  const monthNames = [
    'янв.',
    'фев.',
    'марта',
    'апр.',
    'мая',
    'июня',
    'июля',
    'авг.',
    'сент.',
    'окт.',
    'нояб.',
    'дек.',
  ];
  return monthNames[month - 1];
}

showIntakeDialog(
  String medicationName,
  IntakeRecord record,
  BuildContext context,
  Function(IntakeRecord) onTake,
  Function(IntakeRecord) onSkip,
) {
  showDialog(
    context: context,
    builder: (context) {
      final time = TimeOfDay.fromDateTime(record.scheduledDateTime);
      final isAfter = time.isAfter(TimeOfDay.now());
      return AlertDialog(
        title: Text('Информация о приеме'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Лекарство: $medicationName'),
            Text(
              'Время приема: ${time.hour}:${time.minute.toString().padLeft(2, '0')}',
            ),
          ],
        ),
        actions: isAfter
            ? null
            : [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        onPressed: () {
                          onSkip(record);
                          Navigator.of(context).pop();
                        },
                        child: Text('Пропустить'),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green,
                        ),
                        onPressed: () {
                          onTake(record);
                          Navigator.of(context).pop();
                        },
                        child: Text('Принять'),
                      ),
                    ),
                  ],
                ),
              ],
      );
    },
  );
}
