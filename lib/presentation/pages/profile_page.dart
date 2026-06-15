import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:implicitly_animated_reorderable_list_2/implicitly_animated_reorderable_list_2.dart';
import 'package:pillura_med/core/app_snackbar.dart';
import 'package:pillura_med/core/input_limits.dart';
import 'package:pillura_med/core/theme/profile_link_colors.dart';
import 'package:pillura_med/data/models/add_medication_route_data.dart';
import 'package:pillura_med/data/models/medication_data.dart';
import 'package:pillura_med/data/models/share_medications_route_data.dart';
import 'package:pillura_med/domain/entities/linked_user_access.dart';
import 'package:pillura_med/domain/entities/user_link.dart';
import 'package:pillura_med/domain/enums/course_duration_unit.dart';
import 'package:pillura_med/domain/enums/dosage_type.dart';
import 'package:pillura_med/domain/enums/ward_profile_icon.dart';
import 'package:pillura_med/presentation/providers/auth_providers.dart';
import 'package:pillura_med/presentation/providers/medication_provider.dart';
import 'package:pillura_med/presentation/providers/repository_provider.dart';
import 'package:pillura_med/presentation/widgets/medication_card.dart';
import 'package:pillura_med/presentation/widgets/ward_icon_picker.dart';

import '../../domain/entities/intake_rec/intake_record.dart';
import '../../domain/entities/medication.dart';

enum _MedicationListFilter { today, all }

enum _ProfileCardKind { own, ward, share }

const _fabListBottomPadding =
    kFloatingActionButtonMargin + kMinInteractiveDimension + 8;

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
  _MedicationListFilter _medicationFilter = _MedicationListFilter.today;

  void _resetSelectedProfile() {
    _selectedLinkedUserId = null;
    _selectedLinkedUserName = null;
    _selectedLinkedUserCanEdit = false;
    _selectedLinkedUserType = null;
  }

  void _showLinkedProfileActions(LinkedUserAccess linkedUser) {
    final isWard = linkedUser.linkType == UserLinkType.ward;
    final name = linkedUser.displayTitle;

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(isWard ? 'Редактировать' : 'Переименовать'),
              onTap: () {
                Navigator.pop(sheetContext);
                if (isWard) {
                  _showEditWardDialog(linkedUser);
                } else {
                  _showRenameShareDialog(linkedUser);
                }
              },
            ),
            ListTile(
              leading: Icon(
                Icons.link_off_outlined,
                color: Colors.red.shade700,
              ),
              title: Text(
                isWard ? 'Удалить' : 'Перестать отслеживать',
                style: TextStyle(color: Colors.red.shade700),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmRemoveLink(linkedUser, name);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRenameShareDialog(LinkedUserAccess linkedUser) async {
    final formKey = GlobalKey<FormState>();
    final currentName = linkedUser.displayTitle;
    String? newName;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Переименовать'),
        content: Form(
          key: formKey,
          child: TextFormField(
            initialValue: currentName,
            maxLength: kPersonNameMaxLength,
            decoration: const InputDecoration(
              labelText: 'Имя',
              counterText: '',
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: validatePersonName,
            onSaved: (value) => newName = value?.trim(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              formKey.currentState!.save();
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (saved != true || newName == null || !mounted) return;
    if (newName == currentName) return;

    final error = await ref
        .read(authNotifierProvider.notifier)
        .updateLinkDisplayName(linkedUser.linkId, newName!);

    if (!mounted) return;
    if (error != null) {
      AppSnackBar.show(context, error);
      return;
    }

    ref.invalidate(linkedUsersProvider);
    if (_selectedLinkedUserId == linkedUser.user.uid) {
      setState(() => _selectedLinkedUserName = newName);
    }
    AppSnackBar.show(context, 'Имя обновлено');
  }

  Future<void> _showEditWardDialog(LinkedUserAccess linkedUser) async {
    final formKey = GlobalKey<FormState>();
    final currentName = linkedUser.displayTitle;
    final currentIcon = linkedUser.profileIcon ?? WardProfileIcon.person;
    String? newName;
    var selectedIcon = currentIcon;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Редактировать'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WardIconPicker(
                    selectedIcon: selectedIcon,
                    onSelected: (icon) {
                      setDialogState(() => selectedIcon = icon);
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    initialValue: currentName,
                    maxLength: kPersonNameMaxLength,
                    decoration: const InputDecoration(
                      labelText: 'Имя',
                      counterText: '',
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: validatePersonName,
                    onSaved: (value) => newName = value?.trim(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                formKey.currentState!.save();
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || newName == null || !mounted) return;
    if (newName == currentName && selectedIcon == currentIcon) return;

    final error = await ref.read(authNotifierProvider.notifier).updateLinkDisplayName(
          linkedUser.linkId,
          newName!,
          profileIcon: selectedIcon,
        );

    if (!mounted) return;
    if (error != null) {
      AppSnackBar.show(context, error);
      return;
    }

    ref.invalidate(linkedUsersProvider);
    if (_selectedLinkedUserId == linkedUser.user.uid) {
      setState(() => _selectedLinkedUserName = newName);
    }
    AppSnackBar.show(context, 'Подопечный обновлён');
  }

  Future<void> _confirmRemoveLink(LinkedUserAccess linkedUser, String name) async {
    final isWard = linkedUser.linkType == UserLinkType.ward;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isWard ? 'Удалить подопечного?' : 'Перестать отслеживать?'),
        content: Text(
          isWard
              ? 'Связь с профилем «$name» будет удалена. Его лекарства сохранятся.'
              : 'Профиль «$name» исчезнет из вашего списка — вы больше не будете видеть его лекарства.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(isWard ? 'Удалить' : 'Перестать отслеживать'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final error = await ref
        .read(authNotifierProvider.notifier)
        .revokeUserLink(linkedUser.linkId);

    if (!mounted) return;
    if (error != null) {
      AppSnackBar.show(context, error);
      return;
    }

    ref.invalidate(linkedUsersProvider);
    if (_selectedLinkedUserId == linkedUser.user.uid) {
      setState(_resetSelectedProfile);
    }
    AppSnackBar.show(
      context,
      isWard ? 'Подопечный удалён' : 'Больше не отслеживаете лекарства',
    );
  }

  String? _shareUnavailableReason({
    required bool isGuestMode,
    required bool isWardAccount,
    required bool hasShareStatus,
    required bool isOwnProfileSelected,
    required bool canEditSelectedProfile,
    required UserLinkType? selectedLinkType,
  }) {
    if (isGuestMode) {
      return 'Войдите в аккаунт с email, чтобы делиться списком лекарств';
    }
    if (isWardAccount) {
      return 'Аккаунт подопечного не может делиться списком';
    }
    if (hasShareStatus) {
      return 'Недоступно: у вас только просмотр чужого профиля';
    }
    if (!isOwnProfileSelected && selectedLinkType == UserLinkType.share) {
      return 'Чужим профилем по доступу поделиться нельзя';
    }
    if (!isOwnProfileSelected && !canEditSelectedProfile) {
      return 'Нет прав делиться этим профилем';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(currentUserIdProvider, (previous, next) {
      if (previous == next || !mounted) return;
      setState(_resetSelectedProfile);
    });

    final authUser = ref.watch(authNotifierProvider).value;
    final linkedUsers = ref.watch(linkedUsersProvider);
    final hasShareStatus = linkedUsers.maybeWhen(
      data: (users) =>
          users.any((user) => user.linkType == UserLinkType.share),
      orElse: () => false,
    );
    final isGuestMode = authUser?.isAnonymous == true;
    final isWardAccount = authUser?.isWard == true;
    final canManageSharing = !(isGuestMode || isWardAccount || hasShareStatus);
    final isOwnProfileSelected = _selectedLinkedUserId == null;
    final canEditSelectedProfile =
        isOwnProfileSelected || _selectedLinkedUserCanEdit;
    final canShareSelectedProfile =
        canManageSharing &&
        (isOwnProfileSelected ||
            (_selectedLinkedUserType == UserLinkType.ward &&
                _selectedLinkedUserCanEdit));
    final currentUserId = ref.watch(currentUserIdProvider);
    final selectedUserId = _selectedLinkedUserId ?? currentUserId;
    final medicationsTitle = isOwnProfileSelected
        ? 'Мои лекарства'
        : 'Лекарства ${_selectedLinkedUserName ?? ''}';

    final shareButtonLabel = isOwnProfileSelected
        ? 'Поделиться моими лекарствами'
        : 'Поделиться лекарствами ${_selectedLinkedUserName ?? ''}';

    void openSharePage() {
      if (selectedUserId == null) return;
      context.push(
        '/shareMedications',
        extra: ShareMedicationsRouteData(initialUserId: selectedUserId),
      );
    }

    final shareUnavailableReason = _shareUnavailableReason(
      isGuestMode: isGuestMode,
      isWardAccount: isWardAccount,
      hasShareStatus: hasShareStatus,
      isOwnProfileSelected: isOwnProfileSelected,
      canEditSelectedProfile: canEditSelectedProfile,
      selectedLinkType: _selectedLinkedUserType,
    );
    final showShareButton =
        canShareSelectedProfile &&
        selectedUserId != null &&
        shareUnavailableReason == null;

    final AsyncValue<List<MedicationWithIntakes>> medication =
        selectedUserId == null
        ? const AsyncValue.loading()
        : ref.watch(medicationNotifierProvider(selectedUserId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        centerTitle: false,
        actions: [
          if (showShareButton)
            IconButton(
              tooltip: 'Поделиться',
              onPressed: openSharePage,
              icon: const Icon(Icons.ios_share_rounded),
            ),
          TextButton.icon(
            onPressed: () => context.push('/account'),
            icon: const Icon(Icons.person_2_outlined),
            label: const Text('Аккаунт'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: linkedUsers.when(
              data: (users) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _QrUserCard(
                        title: 'Мой',
                        kind: _ProfileCardKind.own,
                        isSelected: isOwnProfileSelected,
                        onTap: () {
                          setState(_resetSelectedProfile);
                        },
                      ),
                      const SizedBox(width: 12),
                      ...users.map((linkedUser) {
                        final title = linkedUser.displayTitle;
                        if (title.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        final isWard = linkedUser.linkType == UserLinkType.ward;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _QrUserCard(
                            title: title,
                            kind: isWard
                                ? _ProfileCardKind.ward
                                : _ProfileCardKind.share,
                            profileIcon: isWard
                                ? (linkedUser.profileIcon ??
                                      WardProfileIcon.person)
                                    .iconData
                                : null,
                            isSelected:
                                _selectedLinkedUserId == linkedUser.user.uid,
                            onTap: () {
                              setState(() {
                                _selectedLinkedUserId = linkedUser.user.uid;
                                _selectedLinkedUserName = title;
                                _selectedLinkedUserCanEdit = linkedUser.canEdit;
                                _selectedLinkedUserType = linkedUser.linkType;
                              });
                            },
                            onLongPress: () =>
                                _showLinkedProfileActions(linkedUser),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
              loading: () => _QrUserCard(
                title: 'Мой',
                kind: _ProfileCardKind.own,
                isSelected: isOwnProfileSelected,
                onTap: () {
                  setState(_resetSelectedProfile);
                },
              ),
              error: (_, __) => _QrUserCard(
                title: 'Мой',
                kind: _ProfileCardKind.own,
                isSelected: isOwnProfileSelected,
                onTap: () {
                  setState(_resetSelectedProfile);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: double.infinity,
              child: showShareButton
                  ? OutlinedButton.icon(
                      onPressed: openSharePage,
                      icon: const Icon(Icons.ios_share_rounded, size: 20),
                      label: Text(shareButtonLabel),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.indigo.shade800,
                        side: BorderSide(color: Colors.indigo.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    )
                  : OutlinedButton.icon(
                      onPressed: null,
                      icon: Icon(
                        Icons.ios_share_rounded,
                        size: 20,
                        color: Colors.grey.shade500,
                      ),
                      label: Text(
                        isOwnProfileSelected
                            ? 'Поделиться моими лекарствами'
                            : 'Поделиться лекарствами',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
            ),
          ),
          if (showShareButton)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Text(
                'Другой человек сможет видеть список лекарств по QR-коду или ссылке',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Text(
                shareUnavailableReason ??
                    'Поделиться можно своим профилем или подопечным',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Center(
              child: Text(
                medicationsTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _MedicationFilterBar(
            selected: _medicationFilter,
            onChanged: (filter) => setState(() => _medicationFilter = filter),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: medication.when(
              data: (data) {
                final filteredData = _medicationFilter ==
                        _MedicationListFilter.today
                    ? data
                        .where((item) => item.todaysIntakes.isNotEmpty)
                        .toList()
                    : data;

                if (filteredData.isEmpty) {
                  return Center(
                    child: Text(
                      _medicationFilter == _MedicationListFilter.today
                          ? 'На сегодня нет лекарств'
                          : 'Список лекарств пуст',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  );
                }

                return ImplicitlyAnimatedList<MedicationWithIntakes>(
                    items: filteredData,
                    areItemsTheSame: (a, b) =>
                        a.medication.id == b.medication.id,
                    insertDuration: const Duration(milliseconds: 600),
                    removeDuration: const Duration(milliseconds: 400),
                    scrollDirection: Axis.vertical,
                    padding: EdgeInsets.only(
                      bottom: canEditSelectedProfile
                          ? _fabListBottomPadding
                          : 0,
                    ),
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
                );
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
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text(error.toString())),
            ),
          ),
        ),

        // Свайп влево: показывает три кнопки (Удалить, Редактировать, Завершить курс)
        // Требует зависимость: flutter_slidable
        ],
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

class _MedicationFilterBar extends StatelessWidget {
  const _MedicationFilterBar({
    required this.selected,
    required this.onChanged,
  });

  final _MedicationListFilter selected;
  final ValueChanged<_MedicationListFilter> onChanged;

  static const _selectedBackground = Color(0xFFD7E4FA);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<_MedicationListFilter>(
          segments: const [
            ButtonSegment(
              value: _MedicationListFilter.today,
              label: Text('На сегодня'),
            ),
            ButtonSegment(
              value: _MedicationListFilter.all,
              label: Text('Все'),
            ),
          ],
          selected: {selected},
          onSelectionChanged: (selection) {
            if (selection.isNotEmpty) {
              onChanged(selection.first);
            }
          },
          emptySelectionAllowed: false,
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            selectedBackgroundColor: _selectedBackground,
            selectedForegroundColor: Colors.indigo.shade700,
            foregroundColor: Colors.black87,
            backgroundColor: Colors.white,
            side: const BorderSide(color: Colors.blueGrey),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _QrUserCard extends StatelessWidget {
  const _QrUserCard({
    required this.title,
    required this.kind,
    this.profileIcon,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
  });

  final String title;
  final _ProfileCardKind kind;
  final IconData? profileIcon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;

  Color get _borderColor {
    switch (kind) {
      case _ProfileCardKind.own:
        return isSelected
            ? ProfileLinkColors.ownBorderSelected
            : ProfileLinkColors.ownBorder;
      case _ProfileCardKind.ward:
        return isSelected
            ? ProfileLinkColors.wardBorderSelected
            : ProfileLinkColors.wardBorder;
      case _ProfileCardKind.share:
        return isSelected
            ? ProfileLinkColors.shareBorderSelected
            : ProfileLinkColors.shareBorder;
    }
  }

  Color get _backgroundColor {
    if (!isSelected) return Colors.white;
    switch (kind) {
      case _ProfileCardKind.own:
        return ProfileLinkColors.ownProfileSelectedBg;
      case _ProfileCardKind.ward:
        return ProfileLinkColors.wardProfileSelectedBg;
      case _ProfileCardKind.share:
        return ProfileLinkColors.shareProfileSelectedBg;
    }
  }

  Color get _iconColor {
    switch (kind) {
      case _ProfileCardKind.own:
        return isSelected
            ? ProfileLinkColors.ownBorderSelected
            : ProfileLinkColors.ownIcon;
      case _ProfileCardKind.ward:
        return isSelected
            ? ProfileLinkColors.wardBorderSelected
            : ProfileLinkColors.wardIcon;
      case _ProfileCardKind.share:
        return isSelected
            ? ProfileLinkColors.shareBorderSelected
            : ProfileLinkColors.shareIcon;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        height: 92,
        width: 90,
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Icon(
              profileIcon ?? Icons.person_outline_rounded,
              size: 32,
              color: _iconColor,
            ),
          ],
        ),
      ),
    );
  }
}
