import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/services/storage_service.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;

  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fade = Tween(begin: 0.0, end: 1.0).animate(_controller);
    _scale = Tween(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(seconds: 2));

    await _checkBatterySettings(); // ✅ waits for user interaction

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _checkBatterySettings() async {
    final storage = StorageService();

    // ✅ Show ONLY once
    if (storage.isBatteryDialogShown()) return;

    if (_dialogShown) return;
    _dialogShown = true;

    if (!mounted) return;

    await showDialog( // 🔥 IMPORTANT: await here
      context: context,
      barrierDismissible: false, // user must choose
      builder: (_) => AlertDialog(
        title: const Text("Enable Background Running"),
        content: const Text(
          "To ensure reminders work on time, please disable battery optimization and allow background activity.",
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await storage.setBatteryDialogShown(true);
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text("Open Settings"),
          ),
          TextButton(
            onPressed: () async {
              await storage.setBatteryDialogShown(true);
              Navigator.pop(context);
            },
            child: const Text("Later"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),

              FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: _logo(),
                ),
              ),

              const SizedBox(height: 30),

              FadeTransition(
                opacity: _fade,
                child: const Text(
                  AppStrings.appName,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              FadeTransition(
                opacity: _fade,
                child: const Text(
                  AppStrings.appTagline,
                  style: TextStyle(color: Colors.white70),
                ),
              ),

              const SizedBox(height: 40),

              const CircularProgressIndicator(
                color: Colors.white,
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logo() {
    return Container(
      width: 140,
      height: 140,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.medication,
        size: 60,
        color: AppColors.primary,
      ),
    );
  }
}