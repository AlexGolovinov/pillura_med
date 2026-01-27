import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pillura_med/domain/enums/course_duration_unit.dart';
import 'package:pillura_med/domain/enums/dosage_type.dart';
import 'package:pillura_med/presentation/providers/medication_provider.dart';
import 'package:pillura_med/presentation/widgets/medication_card.dart';

import '../../domain/entities/intake_time.dart';
import '../../domain/entities/medication.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final medication = ref.watch(medicationNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: Text('Профили'), centerTitle: false),
      body: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 92,
              width: 62,
              decoration: BoxDecoration(
                color: Color(0xFFE8EFFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.indigo),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('Мой'),
                  Icon(Icons.qr_code_scanner_sharp, size: 35),
                ],
              ),
            ),
            SizedBox(height: 24),
            Center(
              child: Text(
                'Мои лекарства',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            SizedBox(height: 24),
            medication.when(
              data: (data) {
                return Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: MedicationCard(
                          title: data[index].name,
                          dosage: data[index].dosage.toString(),
                          dosageType: data[index].dosageType.shortLabel,
                          startDate: data[index].startDate,
                          intakeTime: data[index].intakeTime,
                          courseInfo: getCourseEndDate(data[index]),
                          color: data[index].color != null
                              ? Color(data[index].color!)
                              : null,
                          deleteMedication: () {
                            ref
                                .read(medicationNotifierProvider.notifier)
                                .deleteMedication(data[index].id);
                          },
                          onTake: (IntakeTime time) {
                            ref
                                .read(medicationNotifierProvider.notifier)
                                .updateIntakeTime(data[index].id, time, true);
                          },
                          onSkip: (IntakeTime time) {
                            ref
                                .read(medicationNotifierProvider.notifier)
                                .updateIntakeTime(data[index].id, time, false);
                          },
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Ошибка загрузки')),
            ),

            // Свайп влево: показывает три кнопки (Удалить, Редактировать, Завершить курс)
            // Требует зависимость: flutter_slidable
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        elevation: 3,
        onPressed: () {
          context.push('/addMedication');
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(Icons.add, size: 45, color: Colors.white),
      ),
      // bottomNavigationBar: BottomAppBar(
      //   height: 70,
      //   shape: CircularNotchedRectangle(),
      //   notchMargin: 8,
      //   child: Row(
      //     mainAxisAlignment: MainAxisAlignment.spaceAround,
      //     children: [
      //       Column(
      //         mainAxisSize: MainAxisSize.min,
      //         children: [Icon(Icons.pie_chart_outline), Text('статистика')],
      //       ),
      //       Column(
      //         children: [Icon(Icons.person_add_outlined), Text('добавить')],
      //       ),
      //     ],
      //   ),
      // ),
    );
  }

  String getCourseEndDate(Medication medication) {
    if (medication.durationTaking != null) {
      final startDate = medication.startDate;
      final int totalDays =
          medication.durationTaking!.count *
          (medication.durationTaking!.unit == CourseDurationUnit.day
              ? 1
              : medication.durationTaking!.unit == CourseDurationUnit.week
              ? 7
              : 30);
      final endDate = startDate.add(Duration(days: totalDays - 1));
      return '${endDate.day} ${getMonthName(endDate.month)}';
    }
    return '';
  }
}
