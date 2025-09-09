import 'package:cloud_firestore/cloud_firestore.dart';
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
    await firestore
        .collection(medicationsCollection)
        .doc(medication.id)
        .set(medication.toJson());
  }

  @override
  Future<void> delete(String id) async {
    await firestore.collection(medicationsCollection).doc(id).delete();
  }
}
