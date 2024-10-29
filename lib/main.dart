import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:prayer_vs/screens/home_screen.dart';
import 'package:prayer_vs/services/database_helper.dart';
import 'package:prayer_vs/services/location_service.dart';
import 'package:prayer_vs/services/notification_service.dart';
import 'package:prayer_vs/services/prayer_time_service.dart';
import 'package:prayer_vs/utils/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure the Flutter engine is initialized

  final notificationService = NotificationService();
  await notificationService.initialize();

  await DatabaseHelper().initDatabase(); // Initialize SQLite database

  final backgroundService = BackgroundService();
  await backgroundService.initialize();


  final locationService = LocationService();
  final prayerTimeService = PrayerTimeService();

  final location = await locationService.getCurrentLocation(); // Get current location
  final prayerTimes = await prayerTimeService.getPrayerTimes(location); // Get prayer times

  await backgroundService.scheduleDailyTask(prayerTimes);

  MobileAds.instance.initialize();


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prayer Reminder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}
