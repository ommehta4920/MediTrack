import 'package:uuid/uuid.dart';
import 'enums.dart';

class MedicationLog {
  final String id;
  final String medicationId;
  final String medicationName; // Stored for history even if medication is deleted
  final String dosage;
  final DateTime scheduledTime;
  final DateTime? takenTime; // When user marked as taken
  final MedicationStatus status;
  final String? notes; // Optional notes for this specific log
  final DateTime createdAt;

  MedicationLog({
    String? id,
    required this.medicationId,
    required this.medicationName,
    required this.dosage,
    required this.scheduledTime,
    this.takenTime,
    this.status = MedicationStatus.pending,
    this.notes,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  // Copy with method for updating
  MedicationLog copyWith({
    String? id,
    String? medicationId,
    String? medicationName,
    String? dosage,
    DateTime? scheduledTime,
    DateTime? takenTime,
    MedicationStatus? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return MedicationLog(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      takenTime: takenTime ?? this.takenTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Convert to JSON (for database storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicationId': medicationId,
      'medicationName': medicationName,
      'dosage': dosage,
      'scheduledTime': scheduledTime.toIso8601String(),
      'takenTime': takenTime?.toIso8601String(),
      'status': status.index,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from JSON (from database)
  factory MedicationLog.fromJson(Map<String, dynamic> json) {
    return MedicationLog(
      id: json['id'] as String,
      medicationId: json['medicationId'] as String,
      medicationName: json['medicationName'] as String,
      dosage: json['dosage'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      takenTime: json['takenTime'] != null
          ? DateTime.parse(json['takenTime'] as String)
          : null,
      status: MedicationStatus.values[json['status'] as int],
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  // Get formatted scheduled time
  String get formattedScheduledTime {
    final hour = scheduledTime.hour;
    final minute = scheduledTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  // Get formatted date
  String get formattedDate {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${scheduledTime.day} ${months[scheduledTime.month - 1]} ${scheduledTime.year}';
  }

  // Check if this log is for today
  bool get isToday {
    final now = DateTime.now();
    return scheduledTime.year == now.year &&
        scheduledTime.month == now.month &&
        scheduledTime.day == now.day;
  }

  // Check if time has passed (for marking as missed)
  bool get isOverdue {
    return DateTime.now().isAfter(scheduledTime) &&
        status == MedicationStatus.pending;
  }

  @override
  String toString() {
    return 'MedicationLog(id: $id, medicationName: $medicationName, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MedicationLog && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}