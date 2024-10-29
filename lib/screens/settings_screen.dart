import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../advertisment/banner_ad.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _notificationTime = 20;
  double _updateDistance = 500; // Default distance in meters
  bool _fajrNotification = true;
  bool _dhuhrNotification = true;
  bool _asrNotification = true;
  bool _maghribNotification = true;
  bool _ishaNotification = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationTime = prefs.getDouble('notificationTime') ?? 20;
      _updateDistance = prefs.getDouble('updateDistance') ?? 50;
      _fajrNotification = prefs.getBool('fajrNotification') ?? true;
      _dhuhrNotification = prefs.getBool('dhuhrNotification') ?? true;
      _asrNotification = prefs.getBool('asrNotification') ?? true;
      _maghribNotification = prefs.getBool('maghribNotification') ?? true;
      _ishaNotification = prefs.getBool('ishaNotification') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('notificationTime', _notificationTime);
    await prefs.setDouble('updateDistance', _updateDistance);
    await prefs.setBool('fajrNotification', _fajrNotification);
    await prefs.setBool('dhuhrNotification', _dhuhrNotification);
    await prefs.setBool('asrNotification', _asrNotification);
    await prefs.setBool('maghribNotification', _maghribNotification);
    await prefs.setBool('ishaNotification', _ishaNotification);
  }

  Future<void> _launchURL() async {
    final url = Uri.parse('https://www.facebook.com/profile.php?id=100007919205769');
    try {
      if (kIsWeb) {
        await launchUrl(url);
      } else {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          _showErrorDialog('Could not launch $url');
        }
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification Time (minutes)',
              style: TextStyle(fontSize: 18),
            ),
            Slider(
              value: _notificationTime,
              min: 1,
              max: 60,
              divisions: 59,
              label: _notificationTime.round().toString(),
              onChanged: (value) {
                setState(() {
                  _notificationTime = value;
                });
                _saveSettings();
              },
            ),
            Text(
              '${_notificationTime.round()} minutes',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'Update Distance (meters)',
              style: TextStyle(fontSize: 18),
            ),
            Slider(
              value: _updateDistance,
              min: 0,
              max: 5000,
              divisions: 100,
              label: _updateDistance.round().toString(),
              onChanged: (value) {
                setState(() {
                  _updateDistance = value;
                });
                _saveSettings();
              },
            ),
            Text(
              '${_updateDistance.round()} meters',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'Enable Notifications for Salah',
              style: TextStyle(fontSize: 18),
            ),
            SwitchListTile(
              title: const Text('Fajr'),
              value: _fajrNotification,
              onChanged: (value) {
                setState(() {
                  _fajrNotification = value;
                  _saveSettings();
                });
              },
            ),
            SwitchListTile(
              title: const Text('Dhuhr'),
              value: _dhuhrNotification,
              onChanged: (value) {
                setState(() {
                  _dhuhrNotification = value;
                  _saveSettings();
                });
              },
            ),
            SwitchListTile(
              title: const Text('Asr'),
              value: _asrNotification,
              onChanged: (value) {
                setState(() {
                  _asrNotification = value;
                  _saveSettings();
                });
              },
            ),
            SwitchListTile(
              title: const Text('Maghrib'),
              value: _maghribNotification,
              onChanged: (value) {
                setState(() {
                  _maghribNotification = value;
                  _saveSettings();
                });
              },
            ),
            SwitchListTile(
              title: const Text('Isha'),
              value: _ishaNotification,
              onChanged: (value) {
                setState(() {
                  _ishaNotification = value;
                  _saveSettings();
                });
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: _launchURL,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Visit the developer’s FB account',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }
}
