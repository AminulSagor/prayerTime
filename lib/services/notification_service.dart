import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  // Define channel properties for Android
  static const String channelId = 'prayer_reminders_channel';
  static const String channelName = 'Prayer Reminders';
  static const String channelDescription = 'Channel for prayer reminder notifications';

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Initialize time zones and permissions for Android
    await _initializeTimezone();
    await _initializePermissions();

    // Set up notification initialization settings for both Android and iOS
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    // Initialize notifications with settings
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Create Android-specific notification channel
    await _createAndroidNotificationChannel();
  }

  Future<void> _initializeTimezone() async {
    // Initialize timezone data and set the local timezone
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  Future<void> _initializePermissions() async {
    await requestNotificationPermission();
    await requestExactAlarmPermission();
  }



  Future<void> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.scheduleExactAlarm.status;

      // Print the permission status to see if it's granted
      print("Exact Alarm Permission status: ${status.isGranted ? 'Granted' : 'Not Granted'}");

      if (!status.isGranted) {
        print("Requesting SCHEDULE_EXACT_ALARM permission...");
        final requestStatus = await Permission.scheduleExactAlarm.request();

        // Print the result after requesting permission
        print("Exact Alarm Permission after request: ${requestStatus.isGranted ? 'Granted' : 'Not Granted'}");

        if (!requestStatus.isGranted) {
          print("SCHEDULE_EXACT_ALARM permission denied. Opening app settings.");
          openAppSettings();
        } else {
          print("SCHEDULE_EXACT_ALARM permission granted.");
        }
      }
    }
  }


  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    int? notificationId,
  }) async {
    try {
      notificationId ??= DateTime.now().millisecondsSinceEpoch.remainder(100000);
      final scheduledTZDateTime = tz.TZDateTime.from(scheduledTime, tz.local);
      print("Scheduled time (local): $scheduledTime");
      print("Scheduled time (TZ): $scheduledTZDateTime");

      if (scheduledTZDateTime.isBefore(tz.TZDateTime.now(tz.local))) {
        print("Error: Scheduled time is in the past.");
        return;
      }

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        scheduledTZDateTime,
        await notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exact,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      print("Notification scheduled with ID $notificationId");
    } catch (e) {
      print("Error scheduling notification: $e");
    }
  }


  Future<NotificationDetails> notificationDetails() async {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
      ),
      iOS: DarwinNotificationDetails(sound: 'notification_sound.mp3'),
    );
  }

  Future<void> requestNotificationPermission() async {
    var status = await Permission.notification.status;
    if (status.isDenied || status.isRestricted || status.isPermanentlyDenied) {
      final result = await Permission.notification.request();
      if (!result.isGranted) {
        print("Notification permission not granted. Opening app settings.");
        openAppSettings();
      }
    }
  }

  Future<void> _createAndroidNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.max,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
}
