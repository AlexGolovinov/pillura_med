import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:implicitly_animated_reorderable_list_2/implicitly_animated_reorderable_list_2.dart';
import 'package:pillura_med/data/models/add_medication_route_data.dart';
import 'package:pillura_med/data/models/medication_data.dart';
import 'package:pillura_med/data/models/share_medications_route_data.dart';
import 'package:pillura_med/domain/entities/user_link.dart';
import 'package:pillura_med/domain/enums/course_duration_unit.dart';
import 'package:pillura_med/domain/enums/dosage_type.dart';
import 'package:pillura_med/presentation/providers/auth_providers.dart';
import 'package:pillura_med/presentation/providers/medication_provider.dart';
import 'package:pillura_med/presentation/providers/repository_provider.dart';
import 'package:pillura_med/presentation/widgets/medication_card.dart';

import '../../domain/entities/intake_rec/intake_record.dart';
import '../../domain/entities/medication.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  String? _selectedLinkedUserId;
  String? _selectedLinkedUserName;
  bool _selectedLinkedUserCanEdit = false;
  UserLinkType? _selectedLinkedUserType;

  void _resetSelectedProfile() {
    _selectedLinkedUserId = null;
    _selectedLinkedUserName = null;
    _selectedLinkedUserCanEdit = false;
    _selectedLinkedUserType = null;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(currentUserIdProvider, (previous, next) {
      if (previous == next || !mounted) return;
      setState(_resetSelectedProfile);
    });

    final linkedUsers = ref.watch(linkedUsersProvider);
    final isOwnProfileSelected = _selectedLinkedUserId == null;
    final canEditSelectedProfile =
        isOwnProfileSelected || _selectedLinkedUserCanEdit;
    final canShareSelectedProfile =
        isOwnProfileSelected ||
        (_selectedLinkedUserType == UserLinkType.ward &&
            _selectedLinkedUserCanEdit);
    final currentUserId = ref.watch(currentUserIdProvider);
    final selectedUserId = _selectedLinkedUserId ?? currentUserId;
    final medicationsTitle = isOwnProfileSelected
        ? 'Мои лекарства'
        : 'Лекарства ${_selectedLinkedUserName ?? ''}';

    final AsyncValue<List<MedicationWithIntakes>> medication =
        selectedUserId == null
        ? const AsyncValue.loading()
        : ref.watch(medicationNotifierProvider(selectedUserId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        centerTitle: false,
        actions: [
          if (canShareSelectedProfile && selectedUserId != null)
            IconButton(
              tooltip: 'Поделиться',
              onPressed: () {
                context.push(
                  '/shareMedications',
                  extra: ShareMedicationsRouteData(initialUserId: selectedUserId),
                );
              },
              icon: const Icon(Icons.ios_share_rounded),
            ),
          TextButton.icon(
            onPressed: () => context.push('/welcomePage'),
            icon: const Icon(Icons.person_2),
            label: const Text('Me'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            linkedUsers.when(
              data: (users) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _QrUserCard(
                        title: 'Мой',
                        isSelected: isOwnProfileSelected,
                        onTap: () {
                          setState(_resetSelectedProfile);
                        },
                      ),
                      const SizedBox(width: 12),
                      ...users.map((linkedUser) {
                        final user = linkedUser.user;
                        final title = (user.name ?? '').trim();
                        if (title.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _QrUserCard(
                            title: title,
                            isSelected: _selectedLinkedUserId == user.uid,
                            onTap: () {
                              setState(() {
                                _selectedLinkedUserId = user.uid;
                                _selectedLinkedUserName = title;
                                _selectedLinkedUserCanEdit = linkedUser.canEdit;
                                _selectedLinkedUserType = linkedUser.linkType;
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
              loading: () => _QrUserCard(
                title: 'Мой',
                isSelected: isOwnProfileSelected,
                onTap: () {
                  setState(_resetSelectedProfile);
                },
              ),
              error: (_, __) => _QrUserCard(
                title: 'Мой',
                isSelected: isOwnProfileSelected,
                onTap: () {
                  setState(_resetSelectedProfile);
                },
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                medicationsTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 24),
            medication.when(
              data: (data) {
                return Expanded(
                  child: ImplicitlyAnimatedList<MedicationWithIntakes>(
                    items: data,
                    areItemsTheSame: (a, b) =>
                        a.medication.id == b.medication.id,
                    insertDuration: const Duration(milliseconds: 600),
                    removeDuration: const Duration(milliseconds: 400),
                    scrollDirection: Axis.vertical,
                    itemBuilder: (context, animation, item, index) {
                      // Создаем анимацию смещения по аналогии с вашим примером
                      final slideAnimation = animation.drive(
                        Tween<Offset>(
                          begin: const Offset(1, 0), // Появляется справа
                          end: Offset.zero, // Встает на место
                        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
                      );

                      return SlideTransition(
                        position: slideAnimation,
                        child: Padding(
                          key: ValueKey(item.medication.id),
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: MedicationCard(
                            medication: item.medication,
                            title: item.medication.name,
                            dosage: item.medication.dosage.toString(),
                            dosageType: item.medication.dosageType.shortLabel,
                            startDate: item.medication.startDate,
                            intakeRecords: item.todaysIntakes,
                            courseInfo: getCourseEndDate(item.medication),
                            color: item.medication.color != null
                                ? Color(item.medication.color!)
                                : null,
                            canEditMedication: canEditSelectedProfile,
                            canTrackIntake: canEditSelectedProfile,
                            onEditMedication: () {
                              if (!canEditSelectedProfile) return;
                              context.push(
                                '/addMedication',
                                extra: AddMedicationRouteData(
                                  medicationData: MedicationData(
                                    isEdit: true,
                                    medication: item.medication,
                                  ),
                                  targetUserId: _selectedLinkedUserId,
                                  targetUserName: _selectedLinkedUserName,
                                  canEdit: canEditSelectedProfile,
                                ),
                              );
                            },
                            deleteMedication: () {
                              if (!canEditSelectedProfile) return;
                              if (selectedUserId == null) return;
                              ref
                                  .read(
                                    medicationNotifierProvider(
                                      selectedUserId,
                                    ).notifier,
                                  )
                                  .deleteMedication(item.medication.id);
                            },
                            onTake: (IntakeRecord record) {
                              if (!canEditSelectedProfile) return;
                              if (selectedUserId == null) return;
                              ref
                                  .read(
                                    medicationNotifierProvider(
                                      selectedUserId,
                                    ).notifier,
                                  )
                                  .updateIntakeTimeFromRecord(record, true);
                            },
                            onSkip: (IntakeRecord record) {
                              if (!canEditSelectedProfile) return;
                              if (selectedUserId == null) return;
                              ref
                                  .read(
                                    medicationNotifierProvider(
                                      selectedUserId,
                                    ).notifier,
                                  )
                                  .updateIntakeTimeFromRecord(record, false);
                            },
                          ),
                        ),
                      );
                    },
                    removeItemBuilder: (context, animation, oldItem) {
                      // При удалении элемент уезжает вправо
                      final slideAnimation = animation.drive(
                        Tween<Offset>(
                          begin: const Offset(1, 0),
                          end: Offset.zero,
                        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
                      );

                      return SlideTransition(
                        position: slideAnimation,
                        child: FadeTransition(
                          opacity: animation,
                          child: MedicationCard(
                            medication: oldItem.medication,
                            title: oldItem.medication.name,
                            dosage: oldItem.medication.dosage.toString(),
                            dosageType:
                                oldItem.medication.dosageType.shortLabel,
                            startDate: oldItem.medication.startDate,
                            intakeRecords: oldItem.todaysIntakes,
                            courseInfo: getCourseEndDate(oldItem.medication),
                            color: oldItem.medication.color != null
                                ? Color(oldItem.medication.color!)
                                : null,
                            canEditMedication: false,
                            canTrackIntake: false,
                            onEditMedication: () {},
                            deleteMedication: () {},
                            onTake: (IntakeRecord p1) {},
                            onSkip: (IntakeRecord p1) {},
                          ),
                        ),
                      );
                    },
                  ),
                  // ListView.builder(
                  //   shrinkWrap: true,
                  //   itemCount: data.length + 1,
                  //   itemBuilder: (context, index) {
                  //     if (index == data.length) {
                  //       return SizedBox(height: 80);
                  //     }
                  //     return Padding(
                  //       padding: const EdgeInsets.only(bottom: 12.0),
                  //       child: MedicationCard(
                  //         title: data[index].medication.name,
                  //         dosage: data[index].medication.dosage.toString(),
                  //         dosageType:
                  //             data[index].medication.dosageType.shortLabel,
                  //         startDate: data[index].medication.startDate,
                  //         intakeRecords: data[index].todaysIntakes,
                  //         courseInfo: getCourseEndDate(data[index].medication),
                  //         color: data[index].medication.color != null
                  //             ? Color(data[index].medication.color!)
                  //             : null,
                  //         deleteMedication: () {
                  //           ref
                  //               .read(medicationNotifierProvider.notifier)
                  //               .deleteMedication(data[index].medication.id);
                  //         },
                  //         onTake: (IntakeRecord record) {
                  //           ref
                  //               .read(medicationNotifierProvider.notifier)
                  //               .updateIntakeTimeFromRecord(record, true);
                  //         },
                  //         onSkip: (IntakeRecord record) {
                  //           ref
                  //               .read(medicationNotifierProvider.notifier)
                  //               .updateIntakeTimeFromRecord(record, false);
                  //         },
                  //       ),
                  //     );
                  //   },
                  // ),
                );
              },
              loading: () => Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text(error.toString())),
            ),

            // Свайп влево: показывает три кнопки (Удалить, Редактировать, Завершить курс)
            // Требует зависимость: flutter_slidable
          ],
        ),
      ),

      floatingActionButton: canEditSelectedProfile
          ? FloatingActionButton(
              elevation: 3,
              onPressed: () {
                context.push(
                  '/addMedication',
                  extra: AddMedicationRouteData(
                    targetUserId: _selectedLinkedUserId,
                    targetUserName: _selectedLinkedUserName,
                    canEdit: canEditSelectedProfile,
                  ),
                );
              },
              backgroundColor: Theme.of(context).primaryColor,
              child: Icon(Icons.add, size: 45, color: Colors.white),
            )
          : null,
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

class _QrUserCard extends StatelessWidget {
  const _QrUserCard({required this.title, this.onTap, this.isSelected = false});

  final String title;
  final VoidCallback? onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 92,
        width: 78,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD7E4FA) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.indigo.shade700 : Colors.indigo,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const Icon(Icons.person_outline_rounded, size: 35),
          ],
        ),
      ),
    );
  }
}
