import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:prayer_vs/screens/settings_screen.dart';
import '../advertisment/banner_ad.dart';
import '../models/prayer_time.dart';
import '../models/user_response.dart';
import '../services/database_helper.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/prayer_time_service.dart';
import 'dart:async';

import 'graph_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final LocationService _locationService = LocationService();
  final PrayerTimeService _prayerTimeService = PrayerTimeService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final NotificationService _notificationService = NotificationService();
  Timer? _missedPrayerTimer;

  List<PrayerTime> _prayerTimes = [];
  List<UserResponse> _userResponses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _requestLocationPermission();
    _locationService.startLocationUpdates((location) {
      _fetchPrayerTimes(location);
    });
    _loadUserResponses();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
  }

  @override
  void dispose() {
    _missedPrayerTimer?.cancel();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return;
    }
  }

  Future<void> _fetchPrayerTimes(LocationData location) async {
    try {
      List<PrayerTime> prayerTimes =
          await _prayerTimeService.getPrayerTimes(location);
      setState(() {
        _prayerTimes = prayerTimes;
        _loading = false;
      });
      _startMissedPrayerTimer();
    } catch (e) {
      setState(() {
        _loading = false;
      });
      print("Error fetching prayer times: $e");
    }
  }

  Future<void> _loadUserResponses() async {
    final responses = await _databaseHelper.getUserResponses();
    setState(() {
      _userResponses = responses;
    });
  }

  PrayerTime? _getCurrentPrayer() {
    if (_prayerTimes.isEmpty) {
      print("Prayer times are empty.");
      return null;
    }

    final now = DateTime.now();
    PrayerTime? lastPrayer = _prayerTimes.last;
    PrayerTime? firstPrayer = _prayerTimes.first;

    for (final prayer in _prayerTimes) {
      if (prayer.isActive(now)) {
        return prayer;
      }
    }

    if (now.isAfter(lastPrayer.endTime) ||
        now.isBefore(firstPrayer.startTime)) {
      return lastPrayer;
    }

    return null;
  }

  PrayerTime? _getNextPrayer() {
    if (_prayerTimes.isEmpty) {
      return null;
    }
    final now = DateTime.now();
    for (final prayer in _prayerTimes) {
      if (now.isBefore(prayer.startTime)) {
        return prayer;
      }
    }
    return _prayerTimes.first;
  }

  // Handle response when the user clicks on "Yes" or "No"
  Future<void> _handleResponse(String response, String prayerName) async {
    final today = DateTime.now();
    final userResponse = UserResponse(
      prayerName: prayerName,
      response: response,
      timestamp: today,
    );

    await _databaseHelper.insertUserResponse(userResponse);

    setState(() {
      _userResponses.add(userResponse);
    });

    _missedPrayerTimer?.cancel();
    print("User response stored: $userResponse");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Response recorded: $response for $prayerName')),
    );
  }

  // Check if a response has been recorded for a specific prayer today
  bool _isResponseRecordedForPrayer(PrayerTime prayer) {
    final now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    // Special handling for Isha: allow responses after midnight but before Fajr
    if (prayer.name == "Isha") {
      return _userResponses.any((response) {
        if (response.prayerName != "Isha") return false;

        // Convert response time to date-only format
        DateTime responseDate = DateTime(
          response.timestamp.year,
          response.timestamp.month,
          response.timestamp.day,
        );

        // Check if response was recorded today, or after midnight but before Fajr
        return responseDate.isAtSameMomentAs(today) ||
            (response.timestamp.isAfter(today) &&
                response.timestamp.hour < 4); // assuming Fajr before 4 am
      });
    }

    // For other prayers, check if there’s a response for today
    return _userResponses.any((response) =>
        response.prayerName == prayer.name &&
        response.timestamp.year == now.year &&
        response.timestamp.month == now.month &&
        response.timestamp.day == now.day);
  }

  // Start timer to automatically record "Missed" if no response
  void _startMissedPrayerTimer() {
    final currentPrayer = _getCurrentPrayer();
    if (currentPrayer != null && !_isResponseRecordedForPrayer(currentPrayer)) {
      final timeLeft = currentPrayer.endTime.difference(DateTime.now());

      _missedPrayerTimer = Timer(timeLeft, () {
        _handleResponse("Missed", currentPrayer.name);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPrayer = _getCurrentPrayer();
    final nextPrayer = _getNextPrayer();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer Reminder'),
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListView.builder(
              shrinkWrap: true, // Allows the ListView to take up only necessary space
              physics: const NeverScrollableScrollPhysics(), // Disables scrolling for the ListView
              itemCount: _prayerTimes.length,
              itemBuilder: (context, index) {
                final prayerTime = _prayerTimes[index];
                String startTimeFormatted =
                DateFormat.jm().format(prayerTime.startTime);
                String endTimeFormatted =
                DateFormat.jm().format(prayerTime.endTime);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Center(
                      child: Text(
                        '${prayerTime.name}: $startTimeFormatted - $endTimeFormatted',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                );
              },
            ),
            if (currentPrayer != null) ...[
              const SizedBox(height: 50), // Reduced height
              Text("Current Prayer: ${currentPrayer.name}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (currentPrayer.name == "Isha" &&
                  nextPrayer != null &&
                  DateTime.now().isBefore(nextPrayer.startTime))
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Sunnah time is finished, but you can still pray until Fajr time arrives.",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.red,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onPressed: _isResponseRecordedForPrayer(currentPrayer) ? null : () => _handleResponse("Yes", currentPrayer.name),
                    child: const Text("Yes"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onPressed: _isResponseRecordedForPrayer(currentPrayer) ? null : () => _handleResponse("No", currentPrayer.name),
                    child: const Text("No"),
                  ),
                ],
              ),
              if (_isResponseRecordedForPrayer(currentPrayer))
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "You have already responded for this prayer today.",
                    style: TextStyle(
                      color: Colors.green,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GraphScreen()),
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "View Performance",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue),
                ),
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }
}
