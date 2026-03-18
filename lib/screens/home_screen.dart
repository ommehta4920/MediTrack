import 'package:flutter/material.dart';
import '../core/constants/app_strings.dart';
import '../core/constants/app_colors.dart';
import '../core/services/storage_service.dart';
import '../core/utils/helpers.dart';
import '../models/models.dart';
import 'add_medication_screen.dart';
import 'history_screen.dart';
import 'about_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  List<Medication> _medications = [];
  List<MedicationLog> _todaysLogs = [];
  Map<String, int> _todaysStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      await _storage.generateTodaysLogs();
      await _storage.updateMissedMedications(gracePeriodMinutes: 60);

      _medications = _storage.getActiveMedications();
      _todaysLogs = _storage.getTodaysLogs();
      _todaysStats = _storage.getTodaysStats();

      _todaysLogs.sort((a, b) {
        if (a.status == MedicationStatus.pending && b.status != MedicationStatus.pending) {
          return -1;
        }
        if (b.status == MedicationStatus.pending && a.status != MedicationStatus.pending) {
          return 1;
        }
        return a.scheduledTime.compareTo(b.scheduledTime);
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.homeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
            tooltip: 'History',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            },
            tooltip: 'About',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsCard(),
              const SizedBox(height: 20),
              _buildTodaysMedicationsSection(),
              const SizedBox(height: 20),
              _buildAllMedicationsSection(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
          );
          if (result == true) {
            await _loadData();
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Medicine'),
      ),
    );
  }

  Widget _buildStatsCard() {
    final total = _todaysStats['total'] ?? 0;
    final taken = _todaysStats['taken'] ?? 0;
    final missed = _todaysStats['missed'] ?? 0;
    final pending = _todaysStats['pending'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Progress",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  AppHelpers.getFriendlyDate(DateTime.now()),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', total, Icons.medication_rounded, Colors.white),
              _buildStatItem('Taken', taken, Icons.check_circle_rounded, Colors.lightGreenAccent),
              _buildStatItem('Missed', missed, Icons.cancel_rounded, Colors.redAccent),
              _buildStatItem('Pending', pending, Icons.schedule_rounded, Colors.amberAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon, Color iconColor) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTodaysMedicationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Today's Schedule",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (_todaysLogs.isEmpty)
          _buildEmptyState('No medications scheduled for today')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _todaysLogs.length,
            itemBuilder: (context, index) => _buildLogCard(_todaysLogs[index]),
          ),
      ],
    );
  }

  Widget _buildLogCard(MedicationLog log) {
    final now = DateTime.now();
    final timeSinceScheduled = now.difference(log.scheduledTime);

    bool isOverdue = false;
    bool canTake = false;

    if (log.status == MedicationStatus.pending) {
      if (timeSinceScheduled.inMinutes > 0 && timeSinceScheduled.inMinutes <= 60) {
        isOverdue = true;
        canTake = true;
      } else if (timeSinceScheduled.inMinutes <= 0) {
        canTake = true;
      }
    }

    Color statusColor;
    IconData statusIcon;

    switch (log.status) {
      case MedicationStatus.taken:
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
        break;
      case MedicationStatus.missed:
        statusColor = AppColors.error;
        statusIcon = Icons.cancel_rounded;
        break;
      case MedicationStatus.skipped:
        statusColor = AppColors.warning;
        statusIcon = Icons.skip_next_rounded;
        break;
      case MedicationStatus.pending:
        if (isOverdue) {
          statusColor = Colors.orange;
          statusIcon = Icons.warning_amber_rounded;
        } else {
          statusColor = AppColors.info;
          statusIcon = Icons.schedule_rounded;
        }
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isOverdue ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isOverdue
            ? BorderSide(color: Colors.orange.shade300, width: 2)
            : BorderSide.none,
      ),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor.withValues(alpha: 0.1),
              child: Icon(statusIcon, color: statusColor),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    log.medicationName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${timeSinceScheduled.inMinutes} min overdue',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              '${log.dosage} • ${log.formattedScheduledTime}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            trailing: _buildTrailingWidget(log),
          ),
          if (log.status == MedicationStatus.pending && canTake)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _markAsTaken(log),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(isOverdue ? 'Take Now' : 'Take'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _markAsSkipped(log),
                      icon: const Icon(Icons.skip_next_rounded, size: 18),
                      label: const Text('Skip'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warning,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrailingWidget(MedicationLog log) {
    if (log.status == MedicationStatus.taken) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
          if (log.takenTime != null)
            Text(
              _formatTakenTime(log.takenTime!),
              style: const TextStyle(fontSize: 10, color: AppColors.textHint),
            ),
        ],
      );
    } else if (log.status == MedicationStatus.missed) {
      return const Icon(Icons.cancel_rounded, color: AppColors.error, size: 28);
    } else if (log.status == MedicationStatus.skipped) {
      return const Icon(Icons.skip_next_rounded, color: AppColors.warning, size: 28);
    }
    return const SizedBox.shrink();
  }

  String _formatTakenTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Future<void> _markAsTaken(MedicationLog log) async {
    await _storage.markAsTaken(log.id);
    await _loadData();
    if (mounted) {
      AppHelpers.showSnackBar(context, '${log.medicationName} marked as taken!');
    }
  }

  Future<void> _markAsSkipped(MedicationLog log) async {
    await _storage.markAsSkipped(log.id);
    await _loadData();
    if (mounted) {
      AppHelpers.showSnackBar(context, '${log.medicationName} skipped');
    }
  }

  Widget _buildAllMedicationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'All Medications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${_medications.length} active',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_medications.isEmpty)
          _buildEmptyState('No medications added yet\nTap + to add your first medication')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _medications.length,
            itemBuilder: (context, index) => _buildMedicationCard(_medications[index]),
          ),
      ],
    );
  }

  Widget _buildMedicationCard(Medication medication) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppHelpers.getColorFromString(medication.color),
          child: Icon(
            medication.medicineType.iconData,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          medication.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${medication.dosage} • ${medication.medicineType.displayName}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            Text(
              'Times: ${medication.formattedTimes}',
              style: const TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
          ],
        ),
        isThreeLine: true,
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddMedicationScreen(medication: medication)),
          );
          if (result == true) {
            await _loadData();
          }
        },
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
          onPressed: () async {
            final confirm = await AppHelpers.showConfirmDialog(
              context: context,
              title: 'Delete Medication',
              message: 'Are you sure you want to delete ${medication.name}?',
            );
            if (confirm) {
              await _storage.deleteMedication(medication.id);
              await _loadData();
              if (mounted) {
                AppHelpers.showSnackBar(context, '${medication.name} deleted', isError: true);
              }
            }
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(
            Icons.medication_outlined,
            size: 60,
            color: AppColors.textHint.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}