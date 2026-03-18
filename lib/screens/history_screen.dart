import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/services/storage_service.dart';
import '../core/utils/helpers.dart';
import '../models/models.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  final StorageService _storage = StorageService();
  late TabController _tabController;

  List<MedicationLog> _allLogs = [];
  Map<String, List<MedicationLog>> _groupedLogs = {};
  bool _isLoading = true;

  int _currentStreak = 0;
  double _adherenceRate = 0.0;
  int _totalTaken = 0;
  int _totalMissed = 0;
  int _totalSkipped = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      _allLogs = _storage.getAllLogs();
      _groupLogs();
      _calculateStatistics();
    } catch (e) {
      debugPrint('Error loading history: $e');
    }

    setState(() => _isLoading = false);
  }

  void _groupLogs() {
    _groupedLogs.clear();

    for (final log in _allLogs) {
      final dateKey = DateFormat('yyyy-MM-dd').format(log.scheduledTime);
      if (_groupedLogs.containsKey(dateKey)) {
        _groupedLogs[dateKey]!.add(log);
      } else {
        _groupedLogs[dateKey] = [log];
      }
    }

    _groupedLogs.forEach((key, logs) {
      logs.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    });
  }

  void _calculateStatistics() {
    _currentStreak = _storage.getCurrentStreak();
    _adherenceRate = _storage.getAdherenceRate(days: 30);

    _totalTaken = _allLogs.where((log) => log.status == MedicationStatus.taken).length;
    _totalMissed = _allLogs.where((log) => log.status == MedicationStatus.missed).length;
    _totalSkipped = _allLogs.where((log) => log.status == MedicationStatus.skipped).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.history),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: AppStrings.statistics),
            Tab(text: AppStrings.history),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildStatisticsTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStreakCard(),
          const SizedBox(height: 16),
          _buildAdherenceCard(),
          const SizedBox(height: 16),
          _buildOverviewCards(),
          const SizedBox(height: 16),
          _buildStorageInfo(),
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _currentStreak.toString(),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            AppStrings.currentStreak,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Text(
            AppStrings.days,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdherenceCard() {
    final percentage = _adherenceRate.toStringAsFixed(1);
    Color progressColor;

    if (_adherenceRate >= 90) {
      progressColor = Colors.green;
    } else if (_adherenceRate >= 70) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  AppStrings.adherenceRate,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const Text(
                  AppStrings.thisMonth,
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _adherenceRate / 100,
                      minHeight: 12,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(progressColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Row(
      children: [
        Expanded(child: _buildStatCard(Icons.check_circle_rounded, _totalTaken.toString(), AppStrings.taken, AppColors.success)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(Icons.cancel_rounded, _totalMissed.toString(), AppStrings.missed, AppColors.error)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(Icons.skip_next_rounded, _totalSkipped.toString(), AppStrings.skipped, AppColors.warning)),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String count, String label, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              count,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageInfo() {
    final info = _storage.getStorageInfo();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Text('App Statistics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.medication_rounded, 'Total Medications', info['totalMedications'].toString()),
            _buildInfoRow(Icons.check_circle_outline, 'Active Medications', info['activeMedications'].toString()),
            _buildInfoRow(Icons.history_rounded, 'Total Logs', info['totalLogs'].toString()),
            _buildInfoRow(Icons.today_rounded, "Today's Logs", info['todaysLogs'].toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_groupedLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 80, color: AppColors.textHint.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text(
              AppStrings.noHistoryYet,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            const Text(
              AppStrings.startTakingMeds,
              style: TextStyle(color: AppColors.textHint),
            ),
          ],
        ),
      );
    }

    final sortedDates = _groupedLogs.keys.toList()..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final dateKey = sortedDates[index];
          final date = DateTime.parse(dateKey);
          final logs = _groupedLogs[dateKey]!;
          return _buildDaySection(date, logs);
        },
      ),
    );
  }

  Widget _buildDaySection(DateTime date, List<MedicationLog> logs) {
    final taken = logs.where((log) => log.status == MedicationStatus.taken).length;
    final total = logs.length;
    final percentage = total > 0 ? (taken / total * 100).toInt() : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppHelpers.getFriendlyDate(date),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE').format(date),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: percentage >= 80 ? AppColors.success : percentage >= 50 ? AppColors.warning : AppColors.error,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$taken/$total ($percentage%)',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) => _buildHistoryLogTile(logs[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryLogTile(MedicationLog log) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (log.status) {
      case MedicationStatus.taken:
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
        statusText = AppStrings.taken;
        break;
      case MedicationStatus.missed:
        statusColor = AppColors.error;
        statusIcon = Icons.cancel_rounded;
        statusText = AppStrings.missed;
        break;
      case MedicationStatus.skipped:
        statusColor = AppColors.warning;
        statusIcon = Icons.skip_next_rounded;
        statusText = AppStrings.skipped;
        break;
      case MedicationStatus.pending:
        statusColor = AppColors.info;
        statusIcon = Icons.schedule_rounded;
        statusText = AppStrings.pending;
        break;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor.withValues(alpha: 0.1),
        child: Icon(statusIcon, color: statusColor, size: 20),
      ),
      title: Text(log.medicationName, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${log.dosage} • Scheduled: ${log.formattedScheduledTime}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12)),
          if (log.takenTime != null)
            Text(
              DateFormat('h:mm a').format(log.takenTime!),
              style: const TextStyle(fontSize: 10, color: AppColors.textHint),
            ),
        ],
      ),
    );
  }
}