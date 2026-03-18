import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/models.dart';
import 'notification_service.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  static SharedPreferences? _prefs;

  // Singleton pattern
  factory StorageService() => _instance;
  StorageService._internal();

  // Keys
  static const String _keyMedications = 'medications';
  static const String _keyLogs = 'medication_logs';
  static const String _keySettings = 'settings';

  // Initialize
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ==================== MEDICATION OPERATIONS ====================

  // Save all medications
  Future<bool> _saveMedications(List<Medication> medications) async {
    final jsonList = medications.map((med) => med.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    return await prefs.setString(_keyMedications, jsonString);
  }

  // Get all medications
  List<Medication> getAllMedications() {
    final jsonString = prefs.getString(_keyMedications);
    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Medication.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // Get active medications only
  List<Medication> getActiveMedications() {
    return getAllMedications().where((med) => med.isActive).toList();
  }

  // Get medication by ID
  Medication? getMedicationById(String id) {
    final medications = getAllMedications();
    try {
      return medications.firstWhere((med) => med.id == id);
    } catch (e) {
      return null;
    }
  }

  // Add new medication
  // Add new medication
  Future<bool> addMedication(Medication medication) async {
    final medications = getAllMedications();
    medications.add(medication);
    final success = await _saveMedications(medications);

    // Schedule notifications
    if (success) {
      await NotificationService().scheduleAllForMedication(medication);
    }

    return success;
  }

  // Update medication
  // Update medication
  Future<bool> updateMedication(Medication medication) async {
    final medications = getAllMedications();
    final index = medications.indexWhere((med) => med.id == medication.id);

    if (index == -1) return false;

    final oldMedication = medications[index];

    // Cancel old notifications
    await NotificationService().cancelMedicationNotifications(
      oldMedication.id,
      oldMedication.times,
    );

    medications[index] = medication;
    final success = await _saveMedications(medications);

    // Schedule new notifications
    if (success) {
      await NotificationService().scheduleAllForMedication(medication);
    }

    return success;
  }

  // Delete medication
  Future<bool> deleteMedication(String id) async {
    final medications = getAllMedications();
    final medication = medications.firstWhere((med) => med.id == id);

    // Cancel notifications
    await NotificationService().cancelMedicationNotifications(
      medication.id,
      medication.times,
    );

    medications.removeWhere((med) => med.id == id);

    // Also delete related logs
    final logs = getAllLogs();
    logs.removeWhere((log) => log.medicationId == id);
    await _saveLogs(logs);

    return await _saveMedications(medications);
  }

  // Toggle medication active status
  Future<bool> toggleMedicationActive(String id, bool isActive) async {
    final medication = getMedicationById(id);
    if (medication == null) return false;

    final updated = medication.copyWith(isActive: isActive);
    return await updateMedication(updated);
  }

  // ==================== MEDICATION LOG OPERATIONS ====================

  // Save all logs
  Future<bool> _saveLogs(List<MedicationLog> logs) async {
    final jsonList = logs.map((log) => log.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    return await prefs.setString(_keyLogs, jsonString);
  }

  // Get all logs
  List<MedicationLog> getAllLogs() {
    final jsonString = prefs.getString(_keyLogs);
    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => MedicationLog.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // Get logs for specific date
  List<MedicationLog> getLogsForDate(DateTime date) {
    final allLogs = getAllLogs();
    return allLogs.where((log) {
      return log.scheduledTime.year == date.year &&
          log.scheduledTime.month == date.month &&
          log.scheduledTime.day == date.day;
    }).toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  // Get today's logs
  List<MedicationLog> getTodaysLogs() {
    return getLogsForDate(DateTime.now());
  }

  // Get logs for specific medication
  List<MedicationLog> getLogsForMedication(String medicationId) {
    final allLogs = getAllLogs();
    return allLogs
        .where((log) => log.medicationId == medicationId)
        .toList()
      ..sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
  }

  // Add new log
  Future<bool> addLog(MedicationLog log) async {
    final logs = getAllLogs();
    logs.add(log);
    return await _saveLogs(logs);
  }

  // Update log
  Future<bool> updateLog(MedicationLog log) async {
    final logs = getAllLogs();
    final index = logs.indexWhere((l) => l.id == log.id);

    if (index == -1) return false;

    logs[index] = log;
    return await _saveLogs(logs);
  }

  // Update log status
  Future<bool> updateLogStatus(
      String logId,
      MedicationStatus status, {
        DateTime? takenTime,
        String? notes,
      }) async {
    final logs = getAllLogs();
    final index = logs.indexWhere((log) => log.id == logId);

    if (index == -1) return false;

    final updatedLog = logs[index].copyWith(
      status: status,
      takenTime: takenTime,
      notes: notes,
    );

    logs[index] = updatedLog;
    return await _saveLogs(logs);
  }

  // Mark as taken
  Future<bool> markAsTaken(String logId, {String? notes}) async {
    return await updateLogStatus(
      logId,
      MedicationStatus.taken,
      takenTime: DateTime.now(),
      notes: notes,
    );
  }

  // Mark as missed
  Future<bool> markAsMissed(String logId, {String? notes}) async {
    return await updateLogStatus(
      logId,
      MedicationStatus.missed,
      notes: notes,
    );
  }

  // Mark as skipped
  Future<bool> markAsSkipped(String logId, {String? notes}) async {
    return await updateLogStatus(
      logId,
      MedicationStatus.skipped,
      notes: notes,
    );
  }

  // Delete log
  Future<bool> deleteLog(String id) async {
    final logs = getAllLogs();
    logs.removeWhere((log) => log.id == id);
    return await _saveLogs(logs);
  }

  // Delete old logs (older than X days)
  Future<bool> deleteOldLogs(int daysOld) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    final logs = getAllLogs();

    logs.removeWhere((log) => log.scheduledTime.isBefore(cutoffDate));
    return await _saveLogs(logs);
  }

  // ==================== STATISTICS ====================

  // Get today's statistics
  Map<String, int> getTodaysStats() {
    final logs = getTodaysLogs();

    int taken = 0;
    int missed = 0;
    int pending = 0;
    int skipped = 0;

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

  // Get adherence rate (last X days)
  double getAdherenceRate({int days = 7}) {
    final startDate = DateTime.now().subtract(Duration(days: days));
    final logs = getAllLogs();

    final relevantLogs = logs.where((log) =>
        log.scheduledTime.isAfter(startDate)
    ).toList();

    if (relevantLogs.isEmpty) return 0.0;

    final taken = relevantLogs.where((log) =>
    log.status == MedicationStatus.taken
    ).length;

    return (taken / relevantLogs.length) * 100;
  }

  // Get current streak (consecutive days of 100% adherence)
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
            (log) => log.status == MedicationStatus.taken ||
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

  // ==================== UTILITY ====================

  // Generate today's logs for all active medications
  Future<void> generateTodaysLogs() async {
    final medications = getActiveMedications();
    final today = DateTime.now();
    final existingLogs = getTodaysLogs();

    for (final medication in medications) {
      // Check if medication should be taken today
      if (!medication.shouldTakeToday()) continue;

      for (final timeStr in medication.times) {
        // Parse time
        final timeParts = timeStr.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        final scheduledTime = DateTime(
          today.year,
          today.month,
          today.day,
          hour,
          minute,
        );

        // Check if log already exists
        final exists = existingLogs.any((log) =>
        log.medicationId == medication.id &&
            log.scheduledTime.hour == hour &&
            log.scheduledTime.minute == minute
        );

        if (!exists) {
          final log = MedicationLog(
            medicationId: medication.id,
            medicationName: medication.name,
            dosage: medication.dosage,
            scheduledTime: scheduledTime,
            status: MedicationStatus.pending,
          );
          await addLog(log);
        }
      }
    }
  }

  // Update missed medications
  // Update missed medications (with grace period)
  Future<void> updateMissedMedications({int gracePeriodMinutes = 60}) async {
    final logs = getAllLogs();
    final now = DateTime.now();
    bool hasChanges = false;

    for (int i = 0; i < logs.length; i++) {
      final log = logs[i];

      // Only check pending logs
      if (log.status != MedicationStatus.pending) continue;

      // Calculate time since scheduled
      final timeSinceScheduled = now.difference(log.scheduledTime);

      // Only mark as missed if grace period has passed
      if (timeSinceScheduled.inMinutes > gracePeriodMinutes) {
        logs[i] = log.copyWith(status: MedicationStatus.missed);
        hasChanges = true;
      }
    }

    if (hasChanges) {
      await _saveLogs(logs);
    }
  }

  // ==================== SETTINGS ====================

  // Save notification enabled status
  Future<bool> setNotificationsEnabled(bool enabled) async {
    return await prefs.setBool('notifications_enabled', enabled);
  }

  // Get notification status
  bool getNotificationsEnabled() {
    return prefs.getBool('notifications_enabled') ?? true;
  }

  // Save first launch status
  Future<bool> setFirstLaunch(bool isFirst) async {
    return await prefs.setBool('first_launch', isFirst);
  }

  // Check if first launch
  bool isFirstLaunch() {
    return prefs.getBool('first_launch') ?? true;
  }

  // ==================== DATA MANAGEMENT ====================

  // Clear all data
  Future<bool> clearAllData() async {
    await prefs.remove(_keyMedications);
    await prefs.remove(_keyLogs);
    return true;
  }

  // Export data as JSON (for backup)
  Map<String, dynamic> exportData() {
    return {
      'medications': getAllMedications().map((m) => m.toJson()).toList(),
      'logs': getAllLogs().map((l) => l.toJson()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };
  }

  // Import data from JSON (for restore)
  Future<bool> importData(Map<String, dynamic> data) async {
    try {
      // Import medications
      if (data['medications'] != null) {
        final List<dynamic> medsJson = data['medications'];
        final medications = medsJson
            .map((json) => Medication.fromJson(json))
            .toList();
        await _saveMedications(medications);
      }

      // Import logs
      if (data['logs'] != null) {
        final List<dynamic> logsJson = data['logs'];
        final logs = logsJson
            .map((json) => MedicationLog.fromJson(json))
            .toList();
        await _saveLogs(logs);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get storage info
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
}