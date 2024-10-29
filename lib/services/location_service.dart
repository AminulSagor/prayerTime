

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LocationData {
  final double latitude;
  final double longitude;

  LocationData({required this.latitude, required this.longitude});
}

class LocationService {

  double _distanceFilter = 100; // Default value

  Future<void> loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _distanceFilter = (prefs.getDouble('updateDistance') ?? 100).clamp(0, 100);
  }
  // Method to get the current location
  Future<LocationData> getCurrentLocation() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    // Check for permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }



    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    // Define the location settings
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high, // Desired accuracy
      distanceFilter: 1000, // Min distance to trigger updates
    );

    // Get the current position with location settings
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );

    // Return the location data
    return LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  void startLocationUpdates(Function(LocationData) onLocationChanged) {
    final positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: _distanceFilter.toInt(),
      ),
    );

    positionStream.listen((Position position) {
      final locationData = LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      onLocationChanged(locationData);
    });
  }
}
