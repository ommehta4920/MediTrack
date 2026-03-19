import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/models.dart';
import 'notification_service.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  static SharedPreferences? _prefs;

  factory StorageService() => _instance;
  StorageService._internal();

  // Keys
  static const String _keyMedications = 'medications';
  static const String _keyLogs = 'medication_logs';
  static const String _keyBatteryDialogShown = 'battery_dialog_shown';

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  List<MedicationLog> getLogsForDate(DateTime date) {
    final allLogs = getAllLogs();

    return allLogs.where((log) {
      return log.scheduledTime.year == date.year &&
          log.scheduledTime.month == date.month &&
          log.scheduledTime.day == date.day;
    }).toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService not initialized.');
    }
    return _prefs!;
  }

  // ==================== ✅ BATTERY ====================

  bool isBatteryDialogShown() {
    return prefs.getBool(_keyBatteryDialogShown) ?? false;
  }

  Future<void> setBatteryDialogShown(bool value) async {
    await prefs.setBool(_keyBatteryDialogShown, value);
  }

  // ==================== MEDICATION ====================

  Future<bool> _saveMedications(List<Medication> medications) async {
    return await prefs.setString(
        _keyMedications,
        jsonEncode(medications.map((m) => m.toJson()).toList()));
  }

  int getCurrentStreak() {
    int streak = 0;
    DateTime checkDate = DateTime.now();

    for (int i = 0; i < 365; i++) {
      final logs = getLogsForDate(checkDate);

      if (logs.isEmpty) {
        checkDate = checkDate.subtract(const Duration(days: 1));
        continue;
      }

      final allTaken = logs.every(
            (log) =>
        log.status == MedicationStatus.taken ||
            log.status == MedicationStatus.skipped,
      );

      if (allTaken) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  double getAdherenceRate({int days = 7}) {
    final startDate = DateTime.now().subtract(Duration(days: days));
    final logs = getAllLogs();

    final relevantLogs =
    logs.where((log) => log.scheduledTime.isAfter(startDate)).toList();

    if (relevantLogs.isEmpty) return 0.0;

    final taken = relevantLogs
        .where((log) => log.status == MedicationStatus.taken)
        .length;

    return (taken / relevantLogs.length) * 100;
  }

  Map<String, dynamic> getStorageInfo() {
    final medications = getAllMedications();
    final logs = getAllLogs();

    return {
      'totalMedications': medications.length,
      'activeMedications': medications.where((m) => m.isActive).length,
      'totalLogs': logs.length,
      'todaysLogs': getTodaysLogs().length,
    };
  }

  List<Medication> getAllMedications() {
    final data = prefs.getString(_keyMedications);
    if (data == null) return [];

    final List decoded = jsonDecode(data);
    return decoded.map((e) => Medication.fromJson(e)).toList();
  }

  List<Medication> getActiveMedications() {
    return getAllMedications().where((m) => m.isActive).toList();
  }

  Future<bool> addMedication(Medication medication) async {
    final list = getAllMedications();
    list.add(medication);

    final success = await _saveMedications(list);

    if (success) {
      await NotificationService().scheduleAllForMedication(medication);
    }

    return success;
  }

  Future<bool> updateMedication(Medication medication) async {
    final list = getAllMedications();
    final index = list.indexWhere((m) => m.id == medication.id);

    if (index == -1) return false;

    await NotificationService().cancelMedicationNotifications(
      list[index].id,
      list[index].times,
    );

    list[index] = medication;

    final success = await _saveMedications(list);

    if (success) {
      await NotificationService().scheduleAllForMedication(medication);
    }

    return success;
  }

  Future<bool> deleteMedication(String id) async {
    final list = getAllMedications();
    final med = list.firstWhere((m) => m.id == id);

    await NotificationService().cancelMedicationNotifications(
      med.id,
      med.times,
    );

    list.removeWhere((m) => m.id == id);

    return await _saveMedications(list);
  }

  // ==================== LOGS ====================

  Future<bool> _saveLogs(List<MedicationLog> logs) async {
    return await prefs.setString(
        _keyLogs,
        jsonEncode(logs.map((l) => l.toJson()).toList()));
  }

  List<MedicationLog> getAllLogs() {
    final data = prefs.getString(_keyLogs);
    if (data == null) return [];

    final List decoded = jsonDecode(data);
    return decoded.map((e) => MedicationLog.fromJson(e)).toList();
  }

  List<MedicationLog> getTodaysLogs() {
    final today = DateTime.now();
    return getAllLogs().where((log) {
      return log.scheduledTime.year == today.year &&
          log.scheduledTime.month == today.month &&
          log.scheduledTime.day == today.day;
    }).toList();
  }

  Future<bool> addLog(MedicationLog log) async {
    final logs = getAllLogs();
    logs.add(log);
    return await _saveLogs(logs);
  }

  Future<bool> updateLog(MedicationLog log) async {
    final logs = getAllLogs();
    final index = logs.indexWhere((l) => l.id == log.id);

    if (index == -1) return false;

    logs[index] = log;
    return await _saveLogs(logs);
  }

  // ==================== ACTIONS ====================

  Future<bool> markAsTaken(String logId) async {
    final logs = getAllLogs();
    final index = logs.indexWhere((l) => l.id == logId);

    if (index == -1) return false;

    logs[index] = logs[index].copyWith(
      status: MedicationStatus.taken,
      takenTime: DateTime.now(),
    );

    return await _saveLogs(logs);
  }

  Future<bool> markAsSkipped(String logId) async {
    final logs = getAllLogs();
    final index = logs.indexWhere((l) => l.id == logId);

    if (index == -1) return false;

    logs[index] = logs[index].copyWith(
      status: MedicationStatus.skipped,
    );

    return await _saveLogs(logs);
  }

  // ==================== TODAY GENERATION ====================

  Future<void> generateTodaysLogs() async {
    final meds = getActiveMedications();
    final today = DateTime.now();
    final existing = getTodaysLogs();

    for (final med in meds) {
      if (!med.shouldTakeToday()) continue;

      for (final time in med.times) {
        final parts = time.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        final scheduled = DateTime(
          today.year,
          today.month,
          today.day,
          hour,
          minute,
        );

        final exists = existing.any((log) =>
        log.medicationId == med.id &&
            log.scheduledTime.hour == hour &&
            log.scheduledTime.minute == minute);

        if (!exists) {
          await addLog(MedicationLog(
            medicationId: med.id,
            medicationName: med.name,
            dosage: med.dosage,
            scheduledTime: scheduled,
            status: MedicationStatus.pending,
          ));
        }
      }
    }
  }

  // ==================== MISSED ====================

  Future<void> updateMissedMedications({int gracePeriodMinutes = 60}) async {
    final logs = getAllLogs();
    final now = DateTime.now();
    bool changed = false;

    for (int i = 0; i < logs.length; i++) {
      if (logs[i].status != MedicationStatus.pending) continue;

      final diff = now.difference(logs[i].scheduledTime);

      if (diff.inMinutes > gracePeriodMinutes) {
        logs[i] = logs[i].copyWith(status: MedicationStatus.missed);
        changed = true;
      }
    }

    if (changed) {
      await _saveLogs(logs);
    }
  }

  // ==================== STATS ====================

  Map<String, int> getTodaysStats() {
    final logs = getTodaysLogs();

    int taken = 0, missed = 0, pending = 0, skipped = 0;

    for (final log in logs) {
      switch (log.status) {
        case MedicationStatus.taken:
          taken++;
          break;
        case MedicationStatus.missed:
          missed++;
          break;
        case MedicationStatus.pending:
          pending++;
          break;
        case MedicationStatus.skipped:
          skipped++;
          break;
      }
    }

    return {
      'total': logs.length,
      'taken': taken,
      'missed': missed,
      'pending': pending,
      'skipped': skipped,
    };


  }
}