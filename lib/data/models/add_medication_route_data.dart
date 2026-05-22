import 'medication_data.dart';

class AddMedicationRouteData {
  final MedicationData? medicationData;
  final String? targetUserId;
  final String? targetUserName;
  final bool canEdit;

  const AddMedicationRouteData({
    this.medicationData,
    this.targetUserId,
    this.targetUserName,
    this.canEdit = true,
  });

  bool get isOwnProfile => targetUserId == null;
}
