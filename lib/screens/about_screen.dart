import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App Logo
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.medication_rounded, size: 60, color: Colors.white),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            AppStrings.appName,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),

          const SizedBox(height: 8),

          const Text(
            AppStrings.appTagline,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),

          const SizedBox(height: 8),

          const Text(
            'Version 1.0.0',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textHint),
          ),

          const SizedBox(height: 32),

          // Features Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('About MediTrack', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  const Text(
                    'MediTrack helps you never forget to take your medications. Set up reminders, track your adherence, and maintain a healthy routine.',
                    style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  const Text('Features:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _buildFeature(Icons.calendar_month_rounded, 'Schedule multiple medications'),
                  _buildFeature(Icons.notifications_active_rounded, 'Daily reminders at specific times'),
                  _buildFeature(Icons.analytics_rounded, 'Track adherence and streaks'),
                  _buildFeature(Icons.history_rounded, 'View detailed history'),
                  _buildFeature(Icons.palette_rounded, 'Customizable medication colors'),
                  _buildFeature(Icons.smartphone_rounded, 'All data stored locally'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Privacy Card
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.privacy_tip_rounded, color: Colors.blue.shade700, size: 32),
                  const SizedBox(height: 8),
                  const Text('Privacy First', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text(
                    'All your medication data is stored locally on your device. We do not collect or share any personal information.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Support Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 32),
                  const SizedBox(height: 8),
                  const Text('Need Help?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text(
                    'Contact us for any questions or feedback.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Email: support@realinfosoft.com')),
                      );
                    },
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('Contact Support'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Made with love
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Made with ', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
              Icon(Icons.favorite_rounded, color: Colors.red, size: 16),
              Text(' in India', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.textSecondary))),
        ],
      ),
    );
  }
}