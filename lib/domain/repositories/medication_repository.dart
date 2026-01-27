import '../entities/medication.dart';
import '../entities/intake_time.dart';

abstract class MedicationRepository {
  Future<List<Medication>> getAll();
  Future<void> add(Medication medication);
  Future<void> delete(String id);
  Future<void> cancelNotificationsForMedication(String medId);
  Future<void> updateIntakeTime(String id, IntakeTime intakeTime, bool isTaken);
}
