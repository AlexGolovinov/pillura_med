import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pillura_med/domain/entities/intake_time.dart';
import 'package:pillura_med/presentation/providers/repository_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/course_duration.dart';
import '../../domain/entities/medication.dart';
import '../../domain/entities/repeat_rule.dart';
import '../../domain/enums/dosage_type.dart';
import '../../domain/enums/meal_relation.dart';
import '../../domain/repositories/medication_repository.dart';

class MedicationNotifier extends AsyncNotifier<List<Medication>> {
  late final MedicationRepository _repo;
  @override
  Future<List<Medication>> build() async {
    _repo = ref.read(
      medicationFRepositoryProvider,
    ); // <- берём репозиторий через провайдер
    final meds = await _repo.getAll();

    // Сортировка по ближайшему предстоящему приему
    final now = TimeOfDay.now();
    meds.sort((a, b) => compareMedications(a, b, now));

    // if (meds.isNotEmpty) {
    //   await NotificationService.scheduleMedication(meds.first);
    // }

    return meds;
  }

  Future<void> add({
    required String name,
    required double dosage,
    required DosageType dosageType,
    required MealRelation mealRelation,
    required RepeatRule interval,
    required List<IntakeTime> intakeTime,
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

    final now = TimeOfDay.now();
    final medId = await _repo.add(med);
    final medWithId = med.copyWith(id: medId);
    final meds = [...?state.value, medWithId];
    meds.sort((a, b) => compareMedications(a, b, now));
    state = AsyncValue.data(meds);
  }

  Future<void> deleteMedication(String id) async {
    await _repo.cancelNotificationsForMedication(id);
    state = AsyncValue.data(
      (state.value ?? []).where((m) => m.id != id).toList(),
    );
    await _repo.delete(id);
  }

  Future<void> updateIntakeTime(
    String id,
    IntakeTime intakeTime,
    bool isTaken,
  ) async {
    // Ждем пока данные загрузятся, если еще не загружены
    final currentMeds = state.value ?? await future;

    final updatedMeds = currentMeds.map((med) {
      if (med.id == id) {
        final updatedIntakeTimes = med.intakeTime.map((time) {
          if (time.time.hour == intakeTime.time.hour &&
              time.time.minute == intakeTime.time.minute) {
            return IntakeTime(isTaken: isTaken, time: time.time);
          }
          return time;
        }).toList();
        return med.copyWith(intakeTime: updatedIntakeTimes);
      }
      return med;
    }).toList();
    state = AsyncValue.data(updatedMeds);
    await _repo.updateIntakeTime(id, intakeTime, isTaken);
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
    final current = state.value;
    if (current != null && keyAndValue.isNotEmpty) {
      final updated = current.map((med) {
        final updatedTimes = med.intakeTime.map((t) {
          final key = 'taken_${med.id}_${t.time.hour}_${t.time.minute}';
          final taken = keyAndValue[key];
          return taken != null ? IntakeTime(isTaken: taken, time: t.time) : t;
        }).toList();

        return med.copyWith(intakeTime: updatedTimes);
      }).toList();

      state = AsyncValue.data(updated);
    }

    for (final key in keyAndValue.keys) {
      final value = keyAndValue[key];
      if (value != null) {
        final id = key.split('_')[1];
        final hour = key.split('_')[2];
        final minute = key.split('_')[3];
        final intakeTime = IntakeTime(
          time: TimeOfDay(hour: int.parse(hour), minute: int.parse(minute)),
        );
        await _repo.updateIntakeTime(id, intakeTime, value);
      }
    }

    // //await _repo.updateIntakeTime(id, intakeTime, isTaken);
    // final updatedMeds = (state.value ?? []).map((med) {
    //   final updatedTimes = med.intakeTime.map((t) {
    //     final key = 'taken_${med.id}_${t.time.hour}_${t.time.minute}';
    //     final taken = keyAndValue[key];
    //     if (taken != null) {
    //       return IntakeTime(isTaken: taken, time: t.time);
    //     }
    //     return t;
    //   }).toList();
    //   return med.copyWith(intakeTime: updatedTimes);
    // }).toList();

    // state = AsyncValue.data(updatedMeds);
  }
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

TimeOfDay? getNextIntake(List<IntakeTime> times, TimeOfDay now) {
  // Так как список отсортирован, просто ищем ПЕРВЫЙ будущий прием
  for (final intake in times) {
    final t = intake.time;
    if (t.hour > now.hour || (t.hour == now.hour && t.minute > now.minute)) {
      return t; // Нашли! Остальные можно не смотреть.
    }
  }
  return null; // Приемов на сегодня не осталось
}

final medicationNotifierProvider =
    AsyncNotifierProvider<MedicationNotifier, List<Medication>>(
      () => MedicationNotifier(),
    );
