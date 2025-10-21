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
    final collection = firestore.collection('medications');
    final docRef = collection.doc(); // создаём ID локально

    final medWithId = medication.copyWith(id: docRef.id);

    await docRef.set(medWithId.toJson());
    // final collection = firestore.collection('medications');

    // // создаём новый документ (с auto id)
    // final docRef = await collection.add({...medication.toJson()});

    // // теперь обновляем id в документе (чтобы Firestore и локальная модель совпадали)
    // await docRef.update({'id': docRef.id});
  }

  @override
  Future<void> delete(String id) async {
    await firestore.collection(medicationsCollection).doc(id).delete();
  }
}
