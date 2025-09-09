import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/medication.dart';
import '../../data/repositories/firebase_medication_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'medication_provider.g.dart';

@riverpod
class MedicationNotifier extends _$MedicationNotifier {
  late final FirebaseMedicationRepository _repo;
  @override
  Future<List<Medication>> build() async {
    final user = FirebaseAuth.instance.currentUser!;
    _repo = FirebaseMedicationRepository(FirebaseFirestore.instance, user.uid);
    return _repo.getAll();
  }

  Future<void> add(Medication med) async {
    state = const AsyncValue.loading();
    await _repo.add(med);
    state = AsyncValue.data(await _repo.getAll());
  }

  Future<void> deleteMedication(String id) async {
    state = const AsyncValue.loading();
    await _repo.delete(id);
    state = AsyncValue.data(await _repo.getAll());
  }
}

// final _medicationRepositoryProvider = Provider<FirebaseMedicationRepository>((
//   ref,
// ) {
//   final user = FirebaseAuth.instance.currentUser!;
//   return FirebaseMedicationRepository(FirebaseFirestore.instance, user.uid);
// });

// final medicationListProvider = FutureProvider<List<Medication>>((ref) async {
//   final repo = ref.watch(_medicationRepositoryProvider);
//   return repo.getAll();
// });

// final medicationActionsProvider = Provider<MedicationActions>((ref) {
//   final repo = ref.watch(_medicationRepositoryProvider);
//   return MedicationActions(repo);
// });

// class MedicationActions {
//   final FirebaseMedicationRepository repo;
//   MedicationActions(this.repo);

//   Future<void> add(Medication med) => repo.add(med);
//   Future<void> delete(String id) => repo.delete(id);
// }
