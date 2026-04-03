import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pillura_med/presentation/providers/repository_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/medication_data.dart';
import '../../domain/entities/course_duration.dart';
import '../../domain/entities/intake_rec/intake_record.dart';
import '../../domain/entities/medication.dart';
import '../../domain/entities/repeat_rule.dart';
import '../../domain/enums/dosage_type.dart';
import '../../domain/enums/meal_relation.dart';
import '../../domain/repositories/medication_repository.dart';

class MedicationWithIntakes {
  final Medication medication;
  final List<IntakeRecord>
  todaysIntakes; // Только на сегодня, отсортированные по времени

  MedicationWithIntakes(this.medication, this.todaysIntakes);

  MedicationWithIntakes copyWith({
    Medication? medication,
    List<IntakeRecord>? todaysIntakes,
  }) {
    return MedicationWithIntakes(
      medication ?? this.medication,
      todaysIntakes ?? this.todaysIntakes,
    );
  }
}

class MedicationNotifier extends AsyncNotifier<List<MedicationWithIntakes>> {
  late final MedicationRepository _repo;
  @override
  Future<List<MedicationWithIntakes>> build() async {
    _repo = ref.read(
      medicationFRepositoryProvider,
    ); // <- берём репозиторий через провайдер
    final meds = await _repo.getAll();

    final todayGroups = <MedicationWithIntakes>[];

    for (final med in meds) {
      final intakes = await _repo.getTodaysIntakes(med.id);
      if (intakes.isNotEmpty) {
        todayGroups.add(MedicationWithIntakes(med, intakes));
      }
    }
    final now = DateTime.now();
    todayGroups.sort((a, b) => compareMedicationGroups(a, b, now));

    return todayGroups;
  }

  Future<void> add({
    required String name,
    required double dosage,
    required DosageType dosageType,
    required MealRelation mealRelation,
    required RepeatRule interval,
    required List<TimeOfDay> intakeTime,

    CourseDuration? durationTaking,
    CourseDuration? durationBreak,
    String? reason,
    String? symptoms,
    int? color,
    required DateTime startDate,
  }) async {
    final med = Medication(
      id: '',
      userId: '',
      name: name,
      dosage: dosage,
      dosageType: dosageType,
      mealRelation: mealRelation,
      repeatRule: interval,
      intakeTime: intakeTime,
      durationTaking: durationTaking,
      withBreak: durationBreak != null,
      durationBreak: durationBreak,
      reason: reason,
      symptoms: symptoms,
      color: color,
      startDate: startDate,
    );
    final t0 = DateTime.now();
    log('Начало добавления лекарства: $t0');
    // 1. Сохраняем лекарство в репозитории → получаем реальный id
    final medId = await _repo.add(med);
    final medWithId = med.copyWith(id: medId);
    final t1 = DateTime.now();
    log(
      'Лекарство добавлено в репозиторий: $t1 (затрачено: ${t1.difference(t0).inMilliseconds} ms)',
    );
    // 2. Определяем, есть ли у этого лекарства приёмы именно на сегодня
    //    (это важно, чтобы сразу решить — попадёт ли оно в список или нет)
    //final today = DateTime.now();
    final todaysIntakes = await _repo.getTodaysIntakes(medWithId.id);
    final t2 = DateTime.now();
    log(
      'Получены приёмы на сегодня: ${todaysIntakes.length} шт (затрачено: ${t2.difference(t1).inMilliseconds} ms)',
    );
    // 3. Берём текущее состояние (если есть)
    final current = state.value ?? <MedicationWithIntakes>[];

    // 4. Формируем обновлённый список
    final updatedList = <MedicationWithIntakes>[];

    // Копируем старые группы, исключая те, у которых уже нет приёмов на сегодня
    // (на случай если кто-то из предыдущих теперь "выпал" — но обычно не нужно)
    for (final group in current) {
      // Опционально: можно здесь перезагружать todaysIntakes для каждого,
      updatedList.add(group);
    }

    // 5. Если у нового лекарства есть приёмы на сегодня → добавляем группу
    if (todaysIntakes.isNotEmpty) {
      final newGroup = MedicationWithIntakes(medWithId, todaysIntakes);
      updatedList.add(newGroup);
    }

    // 6. Сортируем весь список по ближайшему предстоящему приёму
    final now = DateTime.now();
    updatedList.sort((a, b) => compareMedicationGroups(a, b, now));
    log(
      'Список отсортирован (затрачено: ${DateTime.now().difference(t2).inMilliseconds} ms)',
    );
    // 7. Устанавливаем новое состояние
    state = AsyncValue.data(updatedList);
  }

  Future<void> edit(Medication med, Medication medOld) async {
    await _repo.edit(med, medOld);

    final current = state.value ?? [];
    final updatedList = current.map((group) {
      if (group.medication.id == med.id) {
        return group.copyWith(medication: med);
      }
      return group;
    }).toList();

    state = AsyncValue.data(updatedList);
  }

  Future<void> deleteMedication(String id) async {
    state = AsyncValue.data(
      (state.value ?? []).where((m) => m.medication.id != id).toList(),
    );
    await _repo.cancelNotificationsForMedication(id);
    await _repo.delete(id);
  }

  Future<void> updateIntakeTimeFromRecord(
    IntakeRecord record,
    bool isTaken,
  ) async {
    try {
      if (record.medicationId == null) return;
      await _repo.updateIntakeTime(record, isTaken);

      final current = state.value ?? [];

      final updatedList = current.map((group) {
        if (group.medication.id != record.medicationId) {
          return group;
        }

        final updatedIntakes = group.todaysIntakes.map((intake) {
          // Сравниваем по времени (лучше использовать == на DateTime, если есть секунды — можно округлить)
          if (intake.scheduledDateTime.hour == record.scheduledDateTime.hour &&
              intake.scheduledDateTime.minute ==
                  record.scheduledDateTime.minute) {
            return intake.copyWith(
              isTaken: isTaken,
            ); // ← если IntakeRecord тоже имеет copyWith
          }
          return intake;
        }).toList();

        return group.copyWith(todaysIntakes: updatedIntakes);
      }).toList();
      updatedList.sort((a, b) => compareMedicationGroups(a, b, DateTime.now()));
      state = AsyncValue.data(updatedList);
    } catch (e) {
      log('Error updating intake time from record: $e');
    }
  }

  Future<IntakeRecord> getIntakeRecordById(String id) async {
    return await _repo.getIntakeRecordById(id);
  }

  Future<void> syncTakenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    if (prefs.getKeys().isEmpty) return;

    final keyAndValue = <String, bool?>{};
    for (final key in prefs.getKeys()) {
      if (!key.startsWith('taken_')) continue;
      final value = prefs.getBool(key);
      if (value != null) {
        keyAndValue[key] = value;
        prefs.remove(key);
      }
    }
    if (keyAndValue.isEmpty) return;

    try {
      for (final key in keyAndValue.keys) {
        final value = keyAndValue[key];
        if (value != null) {
          final recordId = key.split('_')[2];

          final record = await _repo.getIntakeRecordById(recordId);
          await updateIntakeTimeFromRecord(record, value);
        }
      }
    } catch (e) {
      log('Error syncing taken status from prefs: $e');
    }
  }

  void notifyListChanged() {
    state = AsyncValue.data(state.value ?? []);
  }
}

int compareMedicationGroups(
  MedicationWithIntakes a,
  MedicationWithIntakes b,
  DateTime now,
) {
  int getGroupPriority(MedicationWithIntakes group) {
    final hasNotTaken = group.todaysIntakes.any((i) => i.isTaken == null);

    if (hasNotTaken) return 0;

    final hasFuture = group.todaysIntakes.any(
      (i) => i.scheduledDateTime.isAfter(now),
    );

    if (hasFuture) return 1;

    return 2;
  }

  DateTime getReferenceTime(MedicationWithIntakes group) {
    // ближайшее неотмеченное
    final notTaken =
        group.todaysIntakes.where((i) => i.isTaken == null).toList()
          ..sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));

    if (notTaken.isNotEmpty) {
      return notTaken.first.scheduledDateTime;
    }

    // ближайшее будущее
    final future =
        group.todaysIntakes
            .where((i) => i.scheduledDateTime.isAfter(now))
            .toList()
          ..sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));

    if (future.isNotEmpty) {
      return future.first.scheduledDateTime;
    }

    // иначе последнее по времени
    return group.todaysIntakes.last.scheduledDateTime;
  }

  final priorityA = getGroupPriority(a);
  final priorityB = getGroupPriority(b);

  if (priorityA != priorityB) {
    return priorityA.compareTo(priorityB);
  }

  final timeA = getReferenceTime(a);
  final timeB = getReferenceTime(b);

  return timeA.compareTo(timeB);
}

int compareMedications(Medication a, Medication b, TimeOfDay now) {
  final nextA = getNextIntake(a.intakeTime, now);
  final nextB = getNextIntake(b.intakeTime, now);

  if (nextA == null && nextB == null) return 0;
  if (nextA == null) return 1;
  if (nextB == null) return -1;

  // Сравнение времени (переводим в минуты для точности)
  final minutesA = nextA.hour * 60 + nextA.minute;
  final minutesB = nextB.hour * 60 + nextB.minute;
  return minutesA.compareTo(minutesB);
}

TimeOfDay? getNextIntake(List<TimeOfDay> times, TimeOfDay now) {
  // Так как список отсортирован, просто ищем ПЕРВЫЙ будущий прием
  for (final intake in times) {
    final t = intake;
    if (t.hour > now.hour || (t.hour == now.hour && t.minute > now.minute)) {
      return t; // Нашли! Остальные можно не смотреть.
    }
  }
  return null; // Приемов на сегодня не осталось
}

final medicationNotifierProvider =
    AsyncNotifierProvider<MedicationNotifier, List<MedicationWithIntakes>>(
      () => MedicationNotifier(),
    );
