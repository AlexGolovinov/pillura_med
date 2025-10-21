import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pillura_med/presentation/providers/repository_provider.dart';
import '../../domain/entities/course_duration.dart';
import '../../domain/entities/medication.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/repeat_rule.dart';
import '../../domain/enums/dosage_type.dart';
import '../../domain/enums/meal_relation.dart';
import '../../domain/repositories/medication_repository.dart';
part 'medication_provider.g.dart';

@riverpod
class MedicationNotifier extends _$MedicationNotifier {
  late final MedicationRepository _repo;
  @override
  Future<List<Medication>> build() async {
    _repo = ref.watch(
      medicationFRepositoryProvider,
    ); // <- берём репозиторий через провайдер

    return _repo.getAll();
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

    state = AsyncValue.data([...state.value ?? [], med]);
    await _repo.add(med); // Firestore обновляем асинхронно
  }

  Future<void> deleteMedication(String id) async {
    state = AsyncValue.data(
      (state.value ?? []).where((m) => m.id != id).toList(),
    );
    await _repo.delete(id);
  }
}

final selectedDosageTypeProvider = StateProvider<DosageType?>((ref) => null);
