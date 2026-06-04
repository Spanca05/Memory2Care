import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  static const MethodChannel _timeZoneChannel = MethodChannel(
    'memory2care/timezone',
  );

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  /// Initialize notifications (call once on app startup)
  Future<void> initialize() async {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Initialize timezone data
    tzdata.initializeTimeZones();
    await _configureLocalTimezone();

    // Android initialization
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(initSettings);

    // Request runtime permissions when required (Android 13+ and iOS).
    await _requestNotificationPermissions();

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'medication_channel',
      'Medication Reminders',
      description: 'Notifications for medication reminders',
      importance: Importance.high,
      enableVibration: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final timeZoneId = await _timeZoneChannel.invokeMethod<String>(
        'getTimeZoneId',
      );
      if (timeZoneId != null && timeZoneId.isNotEmpty) {
        tz.setLocalLocation(tz.getLocation(timeZoneId));
        developer.log(
          'Configured timezone from device: $timeZoneId',
          name: 'NotificationService',
        );
        return;
      }
    } catch (e) {
      developer.log(
        'Failed to read timezone from device channel: $e',
        name: 'NotificationService',
        level: 1000,
      );
    }

    tz.setLocalLocation(tz.getLocation('UTC'));
    developer.log(
      'Fallback timezone configured: UTC',
      name: 'NotificationService',
      level: 1000,
    );
  }

  Future<void> _requestNotificationPermissions() async {
    // Request POST_NOTIFICATIONS permission (Android 13+)
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // Request SCHEDULE_EXACT_ALARM permission (Android 12+)
    await Permission.scheduleExactAlarm.request();

    // Request iOS permissions
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Check and log current notification-related permissions (for debugging)
  Future<Map<String, String>> checkNotificationPermissions() async {
    final Map<String, String> statuses = {};

    try {
      final notifStatus = await Permission.notification.status;
      statuses['notification'] = notifStatus.toString();
    } catch (e) {
      statuses['notification'] = 'unknown';
    }

    try {
      final exactStatus = await Permission.scheduleExactAlarm.status;
      statuses['scheduleExactAlarm'] = exactStatus.toString();
    } catch (e) {
      statuses['scheduleExactAlarm'] = 'unknown';
    }

    // Also try to query plugin-level notification enable state where available
    try {
      final androidImpl =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      final areEnabled = await androidImpl?.areNotificationsEnabled();
      statuses['platformNotificationsEnabled'] =
          areEnabled == null
              ? 'unknown'
              : areEnabled
              ? 'true'
              : 'false';
    } catch (e) {
      statuses['platformNotificationsEnabled'] = 'unknown';
    }

    developer.log(
      'Permission statuses: $statuses',
      name: 'NotificationService',
    );
    return statuses;
  }

  /// Show an immediate notification (for demo/testing)
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'medication_channel',
          'Medication Reminders',
          channelDescription: 'Notifications for medication reminders',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Schedule a notification for a specific time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    bool repeatDaily = false,
    AndroidScheduleMode androidScheduleMode =
        AndroidScheduleMode.exactAllowWhileIdle,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'medication_channel',
          'Medication Reminders',
          channelDescription: 'Notifications for medication reminders',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tzDateTime = tz.TZDateTime.from(scheduledTime, tz.local);

    debugPrint(
      'Scheduling notification: id=$id title=$title scheduledTime=$scheduledTime tz=$tzDateTime now=${DateTime.now().toIso8601String()} repeatDaily=$repeatDaily',
    );
    developer.log(
      'Scheduling notification: id=$id, title=$title, scheduledTime=$scheduledTime, tz=${tzDateTime.toString()}, now=${DateTime.now().toIso8601String()}, repeatDaily=$repeatDaily',
      name: 'NotificationService',
    );

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: androidScheduleMode,
        matchDateTimeComponents: repeatDaily ? DateTimeComponents.time : null,
        payload: payload,
      );
      debugPrint('Notification scheduled successfully: id=$id');
      developer.log(
        'Notification scheduled successfully: id=$id',
        name: 'NotificationService',
      );
    } catch (e) {
      developer.log(
        'Error scheduling notification: $e',
        name: 'NotificationService',
        level: 1000,
      );
      rethrow;
    }
  }

  /// Schedule a one-off notification after a relative duration.
  Future<void> scheduleNotificationAfterDuration({
    required int id,
    required String title,
    required String body,
    required Duration delay,
    AndroidScheduleMode androidScheduleMode =
        AndroidScheduleMode.inexactAllowWhileIdle,
    String? payload,
  }) async {
    final targetTime = tz.TZDateTime.now(tz.local).add(delay);

    debugPrint(
      'Relative schedule requested: id=$id delay=$delay targetTime=$targetTime now=${tz.TZDateTime.now(tz.local)}',
    );
    developer.log(
      'Relative schedule requested: id=$id, delay=$delay, targetTime=$targetTime, now=${tz.TZDateTime.now(tz.local)}',
      name: 'NotificationService',
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      targetTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_channel',
          'Medication Reminders',
          channelDescription: 'Notifications for medication reminders',
          importance: Importance.max,
          priority: Priority.max,
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: androidScheduleMode,
      payload: payload,
    );

    debugPrint('Relative notification scheduled successfully: id=$id');
    developer.log(
      'Relative notification scheduled successfully: id=$id',
      name: 'NotificationService',
    );
  }

  /// Schedule daily medication notification
  Future<void> scheduleDailyMedicationReminder({
    required int id,
    required String medicationName,
    required String timeOfDay, // "06:00", "12:00", "18:00"
    String? payload,
  }) async {
    final parts = timeOfDay.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    // If time is in the past, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await scheduleNotification(
      id: id,
      title: 'Time for your medication',
      body: '$medicationName at $timeOfDay',
      scheduledTime: scheduledDate,
      repeatDaily: true,
      payload: payload,
    );
  }

  /// Cancel a notification
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// List all pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    final pendingNotifications =
        await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    developer.log(
      'Pending notifications: ${pendingNotifications.length}',
      name: 'NotificationService',
    );
    for (final notif in pendingNotifications) {
      developer.log(
        'Notification id=${notif.id}, title=${notif.title}, body=${notif.body}',
        name: 'NotificationService',
      );
    }
    return pendingNotifications;
  }

  /// List active notifications currently shown by Android (for debugging)
  Future<List<ActiveNotification>> getActiveNotifications() async {
    final androidImpl =
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    final activeNotifications =
        await androidImpl?.getActiveNotifications() ?? <ActiveNotification>[];
    developer.log(
      'Active notifications: ${activeNotifications.length}',
      name: 'NotificationService',
    );
    return activeNotifications;
  }
}
