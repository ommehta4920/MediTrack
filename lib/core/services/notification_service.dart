import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import '../../models/models.dart';
import 'storage_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Brand color for notifications
  static const Color _notificationColor = Color(0xFF4CAF50);

  // Initialize notification service
  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize timezone
    tzdata.initializeTimeZones();
    final locationName = await _getTimeZoneName();
    tz.setLocalLocation(tz.getLocation(locationName));

    // Android settings - use drawable for small icon
    const androidSettings = AndroidInitializationSettings('ic_notification');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    debugPrint('Notification service initialized');
  }

  Future<String> _getTimeZoneName() async {
    return 'Asia/Kolkata';
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<bool> requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final exactAlarmPermission = await android.requestExactAlarmsPermission();
      debugPrint('Exact alarm permission: $exactAlarmPermission');

      final notificationPermission = await android.requestNotificationsPermission();
      debugPrint('Notification permission: $notificationPermission');

      return (exactAlarmPermission ?? false) && (notificationPermission ?? false);
    }

    final ios = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  Future<bool> areNotificationsEnabled() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }

    return true;
  }

  // Get notification details without large icon
  AndroidNotificationDetails _getAndroidNotificationDetails({
    required String channelId,
    required String channelName,
    required String channelDescription,
  }) {
    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      icon: 'ic_notification',
      color: _notificationColor,
      colorized: true,
      enableVibration: true,
      playSound: true,
      fullScreenIntent: true,
      channelShowBadge: true,
      // Remove large icon - this prevents Flutter icon from showing
      // largeIcon: const DrawableResourceAndroidBitmap('@drawable/ic_notification_large'),
    );
  }

  Future<void> scheduleMedicationNotification({
    required String medicationId,
    required String medicationName,
    required String dosage,
    required String time,
    required MedicineType medicineType,
  }) async {
    try {
      final timeParts = time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final now = tz.TZDateTime.now(tz.local);

      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
        debugPrint('Time has passed today, scheduling for tomorrow');
      }

      debugPrint('Current time: $now');
      debugPrint('Scheduled time: $scheduledDate');
      debugPrint('Time until notification: ${scheduledDate.difference(now)}');

      final notificationId = _generateNotificationId(medicationId, time);

      // Professional notification details with large icon
      final androidDetails = AndroidNotificationDetails(
        'medication_reminders_v1',
        'Medication Reminders',
        channelDescription: 'Notifications for medication reminders',
        importance: Importance.max,
        priority: Priority.high,
        icon: 'ic_notification',
        // largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        color: _notificationColor,
        colorized: true,
        enableVibration: true,
        playSound: true,
        fullScreenIntent: true,
        channelShowBadge: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        notificationId,
        'Time to take your ${medicineType.displayName}',
        '$medicationName - $dosage',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: medicationId,
      );

      debugPrint('Scheduled notification for $medicationName at $time (ID: $notificationId)');
      debugPrint('Notification will appear at: $scheduledDate');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> scheduleAllForMedication(Medication medication) async {
    debugPrint('Scheduling notifications for: ${medication.name}');
    for (final time in medication.times) {
      await scheduleMedicationNotification(
        medicationId: medication.id,
        medicationName: medication.name,
        dosage: medication.dosage,
        time: time,
        medicineType: medication.medicineType,
      );
    }
  }

  Future<void> cancelMedicationNotifications(String medicationId, List<String> times) async {
    for (final time in times) {
      final notificationId = _generateNotificationId(medicationId, time);
      await _notifications.cancel(notificationId);
      debugPrint('Cancelled notification ID: $notificationId');
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('Cancelled all notifications');
  }

  Future<void> rescheduleAllMedications() async {
    final storage = StorageService();
    final medications = storage.getActiveMedications();

    await cancelAllNotifications();

    for (final medication in medications) {
      if (medication.shouldTakeToday()) {
        await scheduleAllForMedication(medication);
      }
    }

    debugPrint('Rescheduled ${medications.length} medications');
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'general_channel_v1',
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'ic_notification',
      // largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      color: _notificationColor,
      colorized: true,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
    );

    debugPrint('Immediate notification shown');
  }

  int _generateNotificationId(String medicationId, String time) {
    final combined = '$medicationId-$time';
    return combined.hashCode.abs() % 2147483647;
  }

  Future<int> getPendingNotificationsCount() async {
    final pending = await _notifications.pendingNotificationRequests();
    return pending.length;
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  Future<void> printPendingNotifications() async {
    final pending = await getPendingNotifications();
    debugPrint('Total pending notifications: ${pending.length}');
    for (final notif in pending) {
      debugPrint('   - ID: ${notif.id}');
      debugPrint('     Title: ${notif.title}');
      debugPrint('     Body: ${notif.body}');
      debugPrint('     Payload: ${notif.payload}');
      debugPrint('');
    }
  }
}