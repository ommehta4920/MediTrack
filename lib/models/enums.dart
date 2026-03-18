import 'package:flutter/material.dart';

/// Status of medication for a specific day
enum MedicationStatus {
  pending,
  taken,
  missed,
  skipped,
}

/// How often the medication repeats
enum RepeatType {
  daily,
  weekly,
  everyXDays,
  asNeeded,
}

/// Type of medication
enum MedicineType {
  pill,
  tablet,
  capsule,
  liquid,
  injection,
  drops,
  inhaler,
  cream,
  patch,
  other,
}

/// Time of day for medication
enum MealTiming {
  beforeMeal,
  afterMeal,
  withMeal,
  anytime,
}

// Extension for MedicationStatus
extension MedicationStatusExtension on MedicationStatus {
  String get displayName {
    switch (this) {
      case MedicationStatus.pending:
        return 'Pending';
      case MedicationStatus.taken:
        return 'Taken';
      case MedicationStatus.missed:
        return 'Missed';
      case MedicationStatus.skipped:
        return 'Skipped';
    }
  }

  IconData get iconData {
    switch (this) {
      case MedicationStatus.pending:
        return Icons.schedule;
      case MedicationStatus.taken:
        return Icons.check_circle;
      case MedicationStatus.missed:
        return Icons.cancel;
      case MedicationStatus.skipped:
        return Icons.skip_next;
    }
  }

  Color getColor(BuildContext context) {
    switch (this) {
      case MedicationStatus.pending:
        return Colors.blue;
      case MedicationStatus.taken:
        return Colors.green;
      case MedicationStatus.missed:
        return Colors.red;
      case MedicationStatus.skipped:
        return Colors.orange;
    }
  }
}

// Extension for RepeatType
extension RepeatTypeExtension on RepeatType {
  String get displayName {
    switch (this) {
      case RepeatType.daily:
        return 'Every Day';
      case RepeatType.weekly:
        return 'Specific Days';
      case RepeatType.everyXDays:
        return 'Every X Days';
      case RepeatType.asNeeded:
        return 'As Needed';
    }
  }
}

// Extension for MedicineType
extension MedicineTypeExtension on MedicineType {
  String get displayName {
    switch (this) {
      case MedicineType.pill:
        return 'Pill';
      case MedicineType.tablet:
        return 'Tablet';
      case MedicineType.capsule:
        return 'Capsule';
      case MedicineType.liquid:
        return 'Liquid';
      case MedicineType.injection:
        return 'Injection';
      case MedicineType.drops:
        return 'Drops';
      case MedicineType.inhaler:
        return 'Inhaler';
      case MedicineType.cream:
        return 'Cream/Ointment';
      case MedicineType.patch:
        return 'Patch';
      case MedicineType.other:
        return 'Other';
    }
  }

  IconData get iconData {
    switch (this) {
      case MedicineType.pill:
        return Icons.medication_rounded;
      case MedicineType.tablet:
        return Icons.medication_rounded;
      case MedicineType.capsule:
        return Icons.medication_liquid;
      case MedicineType.liquid:
        return Icons.local_drink_rounded;
      case MedicineType.injection:
        return Icons.vaccines_rounded;
      case MedicineType.drops:
        return Icons.water_drop_rounded;
      case MedicineType.inhaler:
        return Icons.air_rounded;
      case MedicineType.cream:
        return Icons.sanitizer_rounded;
      case MedicineType.patch:
        return Icons.healing_rounded;
      case MedicineType.other:
        return Icons.medical_services_rounded;
    }
  }
}

// Extension for MealTiming
extension MealTimingExtension on MealTiming {
  String get displayName {
    switch (this) {
      case MealTiming.beforeMeal:
        return 'Before Meal';
      case MealTiming.afterMeal:
        return 'After Meal';
      case MealTiming.withMeal:
        return 'With Meal';
      case MealTiming.anytime:
        return 'Anytime';
    }
  }

  IconData get iconData {
    switch (this) {
      case MealTiming.beforeMeal:
        return Icons.restaurant_menu;
      case MealTiming.afterMeal:
        return Icons.restaurant;
      case MealTiming.withMeal:
        return Icons.dining;
      case MealTiming.anytime:
        return Icons.access_time;
    }
  }
}