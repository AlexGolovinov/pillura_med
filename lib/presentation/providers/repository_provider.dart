import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../data/repositories/firebase_medication_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/medication_repository.dart';

// Провайдер для репозитория авторизации
final authFRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(
    fb.FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );
});

final medicationFRepositoryProvider = Provider<MedicationRepository>((ref) {
  return FirebaseMedicationRepository(
    FirebaseFirestore.instance,
    fb.FirebaseAuth.instance.currentUser!.uid,
  );
});
