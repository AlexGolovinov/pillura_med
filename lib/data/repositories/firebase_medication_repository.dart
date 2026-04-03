import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/notification_service.dart';
import '../../domain/entities/intake_rec/intake_record.dart';
import '../../domain/entities/medication.dart';
import '../../domain/enums/course_duration_unit.dart';
import '../../domain/enums/repeat_rule_type.dart';
import '../../domain/repositories/medication_repository.dart';

class FirebaseMedicationRepository implements MedicationRepository {
  final FirebaseFirestore firestore;
  final String userId;
  static const String medicationsCollection = 'medications';
  static const String intakeRecordsCollection = 'intake_records';

  FirebaseMedicationRepository(this.firestore, this.userId);

  @override
  Future<List<Medication>> getAll() async {
    final snapshot = await firestore
        .collection(medicationsCollection)
        .where('userId', isEqualTo: userId)
        .where('repeatRule.type')
        .get();

    return snapshot.docs.map((doc) => Medication.fromJson(doc.data())).toList();
  }

  @override
  Future<String> add(Medication medication) async {
    final t0 = DateTime.now();
    final collection = firestore.collection(medicationsCollection);
    final docRef = collection.doc(); // создаём ID локально

    final medWithId = medication.copyWith(id: docRef.id, userId: userId);

    await docRef.set(medWithId.toJson());
    final records = await addIntakeRecord(medWithId);
    log(
      'addIntakeRecord добавлено в репозиторий:  (затрачено: ${DateTime.now().difference(t0).inMilliseconds} ms)',
    );
    unawaited(NotificationService.scheduleMedication(records, medWithId));
    return docRef.id;
  }

  @override
  Future<void> edit(Medication medication, Medication oldMedication) async {
    await firestore
        .collection(medicationsCollection)
        .doc(medication.id)
        .update(medication.toJson());
    if (listEquals(medication.intakeTime, oldMedication.intakeTime) &&
        medication.repeatRule == oldMedication.repeatRule &&
        medication.durationTaking == oldMedication.durationTaking) {
      log(
        'Интервалы приёма не изменились, пропускаем обновление расписания уведомлений',
      );
    } else {
      log(' Интервалы приёма изменились, обновляем расписание уведомлений');
    }
  }

  @override
  Future<void> delete(String id) async {
    await firestore
        .collection(intakeRecordsCollection)
        .where('medicationId', isEqualTo: id)
        .get()
        .then((snapshot) {
          for (var doc in snapshot.docs) {
            doc.reference.delete();
          }
        });
    await firestore.collection(medicationsCollection).doc(id).delete();
  }

  @override
  Future<void> deleteIntakeRecord(String medId) async {
    await firestore
        .collection(intakeRecordsCollection)
        .where('medId', isEqualTo: medId)
        .get()
        .then((snapshot) {
          for (var doc in snapshot.docs) {
            doc.reference.delete();
          }
        });
  }

  @override
  Future<void> cancelNotificationsForMedication(String medId) async {
    final doc = await firestore
        .collection(medicationsCollection)
        .doc(medId)
        .get();
    if (!doc.exists) return;
    final med = Medication.fromJson(doc.data()!);
    await NotificationService.cancelMedication(med);
  }

  @override
  Future<void> updateIntakeTime(IntakeRecord intakeRecord, bool isTaken) async {
    final targetDateTime = intakeRecord.scheduledDateTime;
    final query = await firestore
        .collection(intakeRecordsCollection)
        .where('medicationId', isEqualTo: intakeRecord.medicationId)
        .where(
          'scheduledDateTime',
          isGreaterThanOrEqualTo: targetDateTime.toIso8601String(),
        )
        .where(
          'scheduledDateTime',
          isLessThanOrEqualTo: targetDateTime.toIso8601String(),
        )
        .get();

    // Обновляем найденный record
    if (query.docs.isNotEmpty) {
      for (var doc in query.docs) {
        await doc.reference.update({'isTaken': isTaken});
      }
    }
  }

  @override
  Future<List<IntakeRecord>> addIntakeRecord(Medication med) async {
    final records = getTimeListFromInterval(med);
    final batch = firestore.batch();
    final recordsWithIds = <IntakeRecord>[];

    for (final record in records) {
      // Создаем ссылку на новый документ с автогенерируемым ID
      final docRef = firestore.collection(intakeRecordsCollection).doc();
      // Добавляем ID в запись
      final recordWithId = IntakeRecord(
        id: docRef.id,
        medicationId: record.medicationId,
        isTaken: record.isTaken,
        scheduledDateTime: record.scheduledDateTime,
      );
      recordsWithIds.add(recordWithId);
      // Добавляем операцию записи в батч
      batch.set(docRef, recordWithId.toJson());
    }

    // Выполняем все операции одним запросом
    await batch.commit();
    return recordsWithIds;
  }

  @override
  Future<List<IntakeRecord>> getTodaysIntakes(String medicationId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Пример: запрос из Firestore
    final query = firestore
        .collection(intakeRecordsCollection)
        .where('medicationId', isEqualTo: medicationId)
        .where(
          'scheduledDateTime',
          isGreaterThanOrEqualTo: startOfDay.toIso8601String(),
        )
        .where('scheduledDateTime', isLessThan: endOfDay.toIso8601String())
        .orderBy('scheduledDateTime');

    final snapshots = await query.get();
    return snapshots.docs
        .map((doc) => IntakeRecord.fromJson(doc.data()))
        .toList();
  }

  List<IntakeRecord> getTimeListFromInterval(Medication med) {
    final intakeRecords = <IntakeRecord>[];
    final int totalDays =
        med.durationTaking!.count *
        (med.durationTaking!.unit == CourseDurationUnit.day
            ? 1
            : med.durationTaking!.unit == CourseDurationUnit.week
            ? 7
            : 30);

    for (var i = 0; i < totalDays; i++) {
      final currentDate = med.startDate.add(Duration(days: i));
      bool shouldAdd = false;
      switch (med.repeatRule.type) {
        case RepeatRuleType.everyDay:
          shouldAdd = true;
          break;
        case RepeatRuleType.everyOtherDay:
          shouldAdd = i % 2 == 0;
          break;
        case RepeatRuleType.weekly:
          final weekday = currentDate.weekday; // 1 (Mon) - 7 (Sun)
          shouldAdd = med.repeatRule.weekdays!.any(
            (w) => w.isoIndex == weekday,
          );
          break;
      }
      if (shouldAdd) {
        for (var j = 0; j < med.intakeTime.length; j++) {
          final date = DateTime(
            med.startDate.year,
            med.startDate.month,
            med.startDate.day + i,
            med.intakeTime[j].hour,
            med.intakeTime[j].minute,
          );
          final intakeRec = IntakeRecord(
            medicationId: med.id,
            isTaken: null,
            scheduledDateTime: date,
          );
          intakeRecords.add(intakeRec);
        }
      }
    }
    return intakeRecords;
  }

  @override
  Future<List<IntakeRecord>> getIntakeRecords(String medicationId) async {
    final snapshot = await firestore
        .collection(intakeRecordsCollection)
        .where('medicationId', isEqualTo: medicationId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return IntakeRecord.fromJson({...data, 'id': doc.id});
    }).toList();
  }

  @override
  Future<IntakeRecord> getIntakeRecordById(String recordId) async {
    final doc = await firestore
        .collection(intakeRecordsCollection)
        .doc(recordId)
        .get();

    if (!doc.exists) throw Exception("Intake record not found");
    final data = doc.data()!;
    return IntakeRecord.fromJson(data);
  }
}
