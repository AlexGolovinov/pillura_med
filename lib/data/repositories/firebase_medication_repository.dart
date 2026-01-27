import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/notification_service.dart';
import '../../domain/entities/intake_time.dart';
import '../../domain/entities/medication.dart';
import '../../domain/repositories/medication_repository.dart';

class FirebaseMedicationRepository implements MedicationRepository {
  final FirebaseFirestore firestore;
  final String userId;
  static const String medicationsCollection = 'medications';

  FirebaseMedicationRepository(this.firestore, this.userId);

  @override
  Future<List<Medication>> getAll() async {
    final snapshot = await firestore
        .collection(medicationsCollection)
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs.map((doc) => Medication.fromJson(doc.data())).toList();
  }

  @override
  Future<void> add(Medication medication) async {
    final collection = firestore.collection('medications');
    final docRef = collection.doc(); // создаём ID локально

    final medWithId = medication.copyWith(id: docRef.id, userId: userId);

    await docRef.set(medWithId.toJson());
    await NotificationService.scheduleMedication(medWithId);
  }

  @override
  Future<void> delete(String id) async {
    await firestore.collection(medicationsCollection).doc(id).delete();
  }

  @override
  Future<void> cancelNotificationsForMedication(String medId) async {
    final doc = await firestore.collection('medications').doc(medId).get();
    if (!doc.exists) return;
    final med = Medication.fromJson(doc.data()!);
    await NotificationService.cancelMedication(med);
  }

  @override
  Future<void> updateIntakeTime(
    String id,
    IntakeTime intakeTime,
    bool isTaken,
  ) async {
    final docRef = firestore.collection(medicationsCollection).doc(id);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final med = Medication.fromJson(doc.data()!);
    final updatedIntakeTimes = med.intakeTime.map((x) {
      if (x.time.hour == intakeTime.time.hour &&
          x.time.minute == intakeTime.time.minute) {
        return IntakeTime(isTaken: isTaken, time: x.time);
      }
      return x;
    }).toList();

    final updatedMed = med.copyWith(intakeTime: updatedIntakeTimes);
    await docRef.update(updatedMed.toJson());
  }
}
