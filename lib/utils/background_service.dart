import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../models/prayer_time.dart';
import '../services/prayer_time_service.dart';
import '../services/notification_service.dart';
import '../services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundService {
  final NotificationService _notificationService = NotificationService();
  final PrayerTimeService _prayerTimeService = PrayerTimeService();
  final LocationService _locationService = LocationService();

  Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
    await startDailyTask();
  }

  Future<void> startDailyTask() async {
    final DateTime now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final notificationMinutes = prefs.getDouble('notificationTime') ?? 20;

    final location = await _locationService.getCurrentLocation();
    final prayerTimes = await _prayerTimeService.getPrayerTimes(location);

    for (var prayer in prayerTimes) {
      final notificationTime = prayer.endTime.subtract(Duration(minutes: notificationMinutes.round()));
      print('${prayer.name} end time: ${prayer.endTime}');
      if (notificationTime.isAfter(now)) {
        await _notificationService.scheduleNotification(
          title: 'Salah Reminder',
          body: '${prayer.name} is ending soon. Don\'t forget to pray!',
          scheduledTime: notificationTime,
        );
      }
    }

    await scheduleDailyTask(prayerTimes);
  }

  static Future<void> runTask() async {
    final service = BackgroundService();
    await service.startDailyTask();
  }

  Future<void> scheduleDailyTask(List<PrayerTime> prayerTimes) async {
    DateTime? nextFajrTime;

    for (var prayer in prayerTimes) {
      if (prayer.name == 'Fajr') {
        nextFajrTime = prayer.startTime;
        break;
      }
    }

    if (nextFajrTime != null) {
      await AndroidAlarmManager.oneShotAt(
        nextFajrTime,
        0,
        runTask,
        exact: true,
        wakeup: true,
      );
    }
  }
}
