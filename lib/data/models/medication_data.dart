import 'package:pillura_med/domain/entities/medication.dart';

class MedicationData {
  final bool isEdit;
  final Medication medication;

  MedicationData({required this.isEdit, required this.medication});
}
