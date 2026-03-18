import 'package:uuid/uuid.dart';
import 'enums.dart';

class Medication {
  final String id;
  final String name;
  final String dosage;
  final MedicineType medicineType;
  final List<String> times; // Multiple times per day (e.g., ["08:00", "20:00"])
  final DateTime startDate;
  final DateTime? endDate; // Optional end date
  final RepeatType repeatType;
  final List<int>? weeklyDays; // For weekly: [1,3,5] = Mon, Wed, Fri
  final int? intervalDays; // For everyXDays: take every X days
  final MealTiming mealTiming;
  final String? notes;
  final String? color; // Color code for UI
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Medication({
    String? id,
    required this.name,
    required this.dosage,
    this.medicineType = MedicineType.pill,
    required this.times,
    required this.startDate,
    this.endDate,
    this.repeatType = RepeatType.daily,
    this.weeklyDays,
    this.intervalDays,
    this.mealTiming = MealTiming.anytime,
    this.notes,
    this.color,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Copy with method for updating
  Medication copyWith({
    String? id,
    String? name,
    String? dosage,
    MedicineType? medicineType,
    List<String>? times,
    DateTime? startDate,
    DateTime? endDate,
    RepeatType? repeatType,
    List<int>? weeklyDays,
    int? intervalDays,
    MealTiming? mealTiming,
    String? notes,
    String? color,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      medicineType: medicineType ?? this.medicineType,
      times: times ?? this.times,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      repeatType: repeatType ?? this.repeatType,
      weeklyDays: weeklyDays ?? this.weeklyDays,
      intervalDays: intervalDays ?? this.intervalDays,
      mealTiming: mealTiming ?? this.mealTiming,
      notes: notes ?? this.notes,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Convert to JSON (for database storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'medicineType': medicineType.index,
      'times': times.join(','), // Store as comma-separated string
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'repeatType': repeatType.index,
      'weeklyDays': weeklyDays?.join(','),
      'intervalDays': intervalDays,
      'mealTiming': mealTiming.index,
      'notes': notes,
      'color': color,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from JSON (from database)
  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      medicineType: MedicineType.values[json['medicineType'] as int],
      times: (json['times'] as String).split(','),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      repeatType: RepeatType.values[json['repeatType'] as int],
      weeklyDays: json['weeklyDays'] != null
          ? (json['weeklyDays'] as String)
          .split(',')
          .map((e) => int.parse(e))
          .toList()
          : null,
      intervalDays: json['intervalDays'] as int?,
      mealTiming: MealTiming.values[json['mealTiming'] as int],
      notes: json['notes'] as String?,
      color: json['color'] as String?,
      isActive: (json['isActive'] as int) == 1,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  // Get formatted time strings for display
  String get formattedTimes {
    return times.join(', ');
  }

  // Check if medication should be taken today
  bool shouldTakeToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);

    // Check if before start date
    if (today.isBefore(start)) return false;

    // Check if after end date
    if (endDate != null) {
      final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
      if (today.isAfter(end)) return false;
    }

    // Check if medication is active
    if (!isActive) return false;

    switch (repeatType) {
      case RepeatType.daily:
        return true;

      case RepeatType.weekly:
      // weekday: 1 = Monday, 7 = Sunday
        return weeklyDays?.contains(now.weekday) ?? false;

      case RepeatType.everyXDays:
        if (intervalDays == null || intervalDays! <= 0) return false;
        final daysDiff = today.difference(start).inDays;
        return daysDiff % intervalDays! == 0;

      case RepeatType.asNeeded:
        return true; // Always available for "as needed" medications
    }
  }

  @override
  String toString() {
    return 'Medication(id: $id, name: $name, dosage: $dosage)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Medication && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}