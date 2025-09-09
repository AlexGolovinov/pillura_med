import '../entities/medication.dart';

abstract class MedicationRepository {
  Future<List<Medication>> getAll();
  Future<void> add(Medication medication);
  Future<void> delete(String id);
}
