import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/services/storage_service.dart';
import '../core/utils/helpers.dart';
import '../models/models.dart';

class AddMedicationScreen extends StatefulWidget {
  final Medication? medication; // For editing existing medication

  const AddMedicationScreen({super.key, this.medication});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();

  final StorageService _storage = StorageService();

  MedicineType _selectedMedicineType = MedicineType.tablet;
  List<String> _selectedTimes = [];
  DateTime _startDate = DateTime.now();
  MealTiming _mealTiming = MealTiming.afterMeal;
  Color _selectedColor = AppColors.primary;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.medication != null) {
      _loadMedicationData();
    }
  }

  void _loadMedicationData() {
    final med = widget.medication!;
    _nameController.text = med.name;
    _dosageController.text = med.dosage;
    _notesController.text = med.notes ?? '';
    _selectedMedicineType = med.medicineType;
    _selectedTimes = List.from(med.times);
    _startDate = med.startDate;
    _mealTiming = med.mealTiming;
    _selectedColor = AppHelpers.getColorFromString(med.color);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      final timeString = AppHelpers.timeOfDayToString(picked);

      // Check if time already exists
      if (_selectedTimes.contains(timeString)) {
        if (mounted) {
          AppHelpers.showSnackBar(
            context,
            'This time is already added',
            isError: true,
          );
        }
        return;
      }

      setState(() {
        _selectedTimes.add(timeString);
        _selectedTimes.sort(); // Sort times in ascending order
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  void _removeTime(String time) {
    setState(() {
      _selectedTimes.remove(time);
    });
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTimes.isEmpty) {
      AppHelpers.showSnackBar(
        context,
        AppStrings.pleaseSelectTime,
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final medication = Medication(
        id: widget.medication?.id,
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim(),
        medicineType: _selectedMedicineType,
        times: _selectedTimes,
        startDate: _startDate,
        mealTiming: _mealTiming,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        color: AppHelpers.colorToString(_selectedColor),
      );

      if (widget.medication == null) {
        await _storage.addMedication(medication);
      } else {
        await _storage.updateMedication(medication);
      }

      if (mounted) {
        AppHelpers.showSnackBar(
          context,
          widget.medication == null
              ? AppStrings.medicationAdded
              : AppStrings.medicationUpdated,
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(
          context,
          'Error saving medication: $e',
          isError: true,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.medication == null
              ? AppStrings.addMedication
              : AppStrings.editMedication,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Medicine Name
            _buildSectionTitle(AppStrings.medicineName, isRequired: true),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: AppStrings.medicineNameHint,
                prefixIcon: const Icon(Icons.medication),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppStrings.pleaseEnterMedicineName;
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: 24),

            // Dosage
            _buildSectionTitle(AppStrings.dosage, isRequired: true),
            TextFormField(
              controller: _dosageController,
              decoration: InputDecoration(
                hintText: AppStrings.dosageHint,
                prefixIcon: const Icon(Icons.local_pharmacy),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppStrings.pleaseEnterDosage;
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Medicine Type
            _buildSectionTitle(AppStrings.medicineType),
            const SizedBox(height: 8),
            _buildMedicineTypeSelector(),

            const SizedBox(height: 24),

            // Times
            _buildSectionTitle(AppStrings.times, isRequired: true),
            const SizedBox(height: 8),
            _buildTimesSection(),

            const SizedBox(height: 24),

            // Start Date
            _buildSectionTitle(AppStrings.startDate),
            const SizedBox(height: 8),
            _buildDateSelector(),

            const SizedBox(height: 24),

            // Meal Timing
            _buildSectionTitle(AppStrings.mealTiming),
            const SizedBox(height: 8),
            _buildMealTimingSelector(),

            const SizedBox(height: 24),

            // Color
            _buildSectionTitle(AppStrings.color),
            const SizedBox(height: 8),
            _buildColorSelector(),

            const SizedBox(height: 24),

            // Notes
            _buildSectionTitle(AppStrings.notes),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: AppStrings.notesHint,
                prefixIcon: const Icon(Icons.note),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveMedication,
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Text(
                  widget.medication == null
                      ? AppStrings.save
                      : AppStrings.update,
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (isRequired)
            const Text(
              ' *',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 16,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMedicineTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: MedicineType.values.map((type) {
        final isSelected = _selectedMedicineType == type;
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(type.iconData, size: 18),
              const SizedBox(width: 4),
              Text(type.displayName),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedMedicineType = type;
            });
          },
          selectedColor: AppColors.primary.withOpacity(0.2),
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedTimes.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedTimes.map((time) {
              return Chip(
                label: Text(AppHelpers.formatTime(time)),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => _removeTime(time),
                backgroundColor: AppColors.primary.withOpacity(0.1),
                labelStyle: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _selectTime,
          icon: const Icon(Icons.access_time),
          label: Text(AppStrings.addTime),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              AppHelpers.formatDate(_startDate),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTimingSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: MealTiming.values.map((timing) {
        final isSelected = _mealTiming == timing;
        return ChoiceChip(
          label: Text(timing.displayName),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _mealTiming = timing;
            });
          },
          selectedColor: AppColors.primary.withOpacity(0.2),
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorSelector() {
    final colors = AppHelpers.getMedicationColors();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: colors.map((color) {
        final isSelected = _selectedColor.value == color.value;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedColor = color;
            });
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.textPrimary : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isSelected
                ? const Icon(
              Icons.check,
              color: Colors.white,
              size: 28,
            )
                : null,
          ),
        );
      }).toList(),
    );
  }
}