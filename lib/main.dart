import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'core/constants/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'core/services/storage_service.dart';
import 'core/services/notification_service.dart';
import 'screens/splash_screen.dart';

Future<void> requestBatteryOptimization() async {
  await Permission.ignoreBatteryOptimizations.request();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize storage
  await StorageService().init();

  // Initialize notifications
  await NotificationService().init();

  // Request notification permissions
  await NotificationService().requestPermissions();

  // 🔥 Request battery optimization ignore
  await requestBatteryOptimization();

  // Reschedule all notifications
  await NotificationService().rescheduleAllMedications();

  // Error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };

  runApp(const MediTrackApp());
}

class MediTrackApp extends StatelessWidget {
  const MediTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}