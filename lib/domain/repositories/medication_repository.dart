import 'package:pillura_med/data/models/medication_data.dart';
import 'package:pillura_med/domain/entities/intake_rec/intake_record.dart';

import '../entities/medication.dart';

abstract class MedicationRepository {
  Future<List<Medication>> getAll();
  Future<String> add(Medication medication);
  Future<void> edit(Medication medication, Medication medicationOld);
  Future<void> delete(String id);
  Future<void> cancelNotificationsForMedication(String medId);
  Future<void> updateIntakeTime(IntakeRecord intakeRecord, bool isTaken);
  Future<void> addIntakeRecord(Medication medication);
  Future<void> deleteIntakeRecord(String id);
  Future<List<IntakeRecord>> getIntakeRecords(String medicationId);
  Future<List<IntakeRecord>> getTodaysIntakes(String medicationId);
  Future<IntakeRecord> getIntakeRecordById(String recordId);
}
