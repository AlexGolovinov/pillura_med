import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pillura_med/domain/entities/intake_time.dart';
import 'package:pillura_med/presentation/providers/repository_provider.dart';
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

    final meds = [...?state.value, med];

    final now = TimeOfDay.now();
    meds.sort((a, b) => compareMedications(a, b, now));
    state = AsyncValue.data(meds);
    await _repo.add(med); // Firestore обновляем асинхронно
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
    final updatedMeds = (state.value ?? []).map((med) {
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
